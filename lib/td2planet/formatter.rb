#--
# -*- mode: ruby; coding: utf-8 -*-
# vim: set filetype=ruby ts=2 sw=2 sts=2 fenc=utf-8:
#
# copyright (c) 2006, 2007 Kazuhiro NISHIYAMA
#++

require 'erb'
require 'nkf'
require 'uri'
require 'rss/maker'

module TD2Planet
  class Formatter
    include ERB::Util

    ERB_METHODS = []
    def self.def_erb_method(method_name, fname=nil)
      if /\A\w+/ =~ method_name
        fname ||= "#{$&}.rhtml"
      end
      ERB_METHODS << [method_name, fname]
    end
    def_erb_method('layout(days)')
    def_erb_method('day(items, rss)')
    def_erb_method('section(item, rss)')
    def_erb_method('header()')
    def_erb_method('footer()')

    def k(s)
      NKF.nkf('-wm0', s.to_s)
    end
    def hk(s)
      h(k(s))
    end

    def default_templates_dir
      basename = 'layout.rhtml'
      dir = File.expand_path('../../data/td2planet/templates', File.dirname(__FILE__))
      if File.exist?(File.join(dir, basename))
        return dir
      end

      require 'rbconfig'
      dir = File.expand_path('td2planet/templates', Config::CONFIG['datadir'])
      if File.exist?(File.join(dir, basename))
       return dir
      end
      raise "not found templates"
    end

    def initialize(config)
      @config = config
      @config['title'] ||= '(no title Planet)'
      @config['tdiary_theme_path'] ||= '/tdiary/theme'
      @config['tdiary_theme'] ||= 'default'
      @config['date_strftime_format'] ||= '%Y-%m-%d'
      @config['sanchor_strftime_format'] ||= '%H:%M:%S'
      @base_uri = URI.parse(@config['base_uri'])
      @config['templates_path'] ||= []
      @config['templates_path'].push(default_templates_dir)
      ERB_METHODS.each do |method_name, basename|
        @config['templates_path'].find do |dir|
          fname = File.expand_path(basename, dir)
          if File.exist?(fname)
            puts "use template #{basename}: #{fname}"
            erb = ERB.new(File.read(fname), nil, '-')
            eval("def self.#{method_name}\n#{erb.src}\nend\n", binding, fname, 0)
            true
          else
            false
          end
        end
      end
    end

    def date_format(item)
      return "" unless item.respond_to?(:date) && item.date
      item.date.localtime.strftime(@config['date_strftime_format'])
    end
    def sanchor_format(item)
      return "" unless item.respond_to?(:date) && item.date
      item.date.localtime.strftime(@config['sanchor_strftime_format'])
    end

    def too_old?(item, sec=7*24*60*60)
      return false unless item.respond_to?(:date) && item.date
      item.date < Time.now - sec
    end

    # override
    def skip?(item)
      false
    end

    def to_html(rss_list)
      @rss_list = rss_list
      day_rss = {}
      rss_list.each do |rss|
        next unless rss.items
        rss.items.each do |item|
          next if skip?(item)
          day = (day_rss[[date_format(item), rss]] ||= Array.new)
          day.push(item)
        end
      end
      days = []
      day_rss.keys.sort_by do |date, rss|
        date
      end.reverse_each do |key|
        date, rss = key
        items = day_rss[key]
        items = items.sort_by do |item|
          # tdiary makerss plugin generates same time entries
          item.date.to_s + item.link
        end
        days << {:items => items, :rss => rss}
      end
      days = days.sort_by do |day|
        -day[:items].collect{|item| item.date.to_i}.max
      end
      layout(days)
    end

    def relative_path_to_absolute_uri(attr_value, base_uri)
      uri = URI.parse(attr_value)
      if uri.scheme.nil?
        URI.parse(base_uri) + uri
      else
        uri
      end
    rescue URI::InvalidURIError
      attr_value
    end

    def tag_attr_relative_path_to_absolute_uri(tag, attr_name, base_uri)
      tag.gsub!(/#{attr_name}=([\"\'])([^\"\']+)\1/i) do
        %Q!#{attr_name}=#{$1}#{relative_path_to_absolute_uri($2, base_uri)}#{$1}!
      end or tag.gsub!(/#{attr_name}=(\S+)/) do
        %Q!#{attr_name}=#{relative_path_to_absolute_uri($1, base_uri)}!
      end
      tag
    end

    def to_section_body(item)
      if item.respond_to?(:content_encoded) && item.content_encoded
        k(item.content_encoded).gsub(/<([aA]\b[\s\S]+?)>/) do
          a = tag_attr_relative_path_to_absolute_uri($1, "href", item.link)
          %Q!<#{a} rel="nofollow">!
        #end.gsub(/<img\b[\s\S]+?>/i) do
        #  tag_attr_relative_path_to_absolute_uri($&, "src", item.link)
        end.gsub(/<img\b[\s\S]+?>/i) do
          img = $&
          case img
          when /alt=([\"\'])(.+?)\1/
            $2
          when /alt=(\S+?)/
            $1
          else
            "[img]"
          end
        end
      else
        '<p>' + h(k(item.description)).gsub(/\r?\n/, '<br>') + '</p>'
      end
    end

    def to_sanchor(item)
      %Q!<a href="#{hk item.link}"><span class="sanchor">#{h sanchor_format(item)}</span></a> !
    end

    def to_categories(item)
      return "" unless item.respond_to?(:dc_subjects)
      h(item.dc_subjects.collect{|s|"[#{k(s.content)}]" if /./ =~ s.content})
    end

    def to_author(item)
      if item.respond_to?(:dc_creator) && item.dc_creator
        " (#{hk(item.dc_creator)})"
      else
        ""
      end
    end

    TukkomiLinkRe = /^<p><a href="(.+)">ツッコミを入れる<\/a><\/p>$/
    def move_tukkomi_link(html)
      if TukkomiLinkRe =~ html
        tukkomi_link = $&
        tukkomi_uri = $1
        re = Regexp.new(Regexp.quote(tukkomi_link))
        tukkomi_moved_html = html.gsub(re, '')
        re = Regexp.new(Regexp.quote('<!--<div class="caption"></div>-->'))
        tukkomi_moved_html.sub!(re) { %Q|<div class="caption">[<a href="#{tukkomi_uri}">ツッコミを入れる</a>]</div>| }
        # other day tukkomi_link found
        if TukkomiLinkRe =~ tukkomi_moved_html
          html.gsub!(TukkomiLinkRe) { %Q|<div class="caption">[<a href="#{$1}">ツッコミを入れる</a>]</div>| }
        else
          html = tukkomi_moved_html
        end
      end
      html
    end


    def_erb_method('to_opml(rss_list)', 'opml.rxml')

    def to_rss(rss_list, version='1.0', basename='rss.xml')
      RSS::Maker.make(version) do |maker|
        maker.channel.about = @base_uri + basename
        maker.channel.title = @config['title']
        maker.channel.link = @base_uri
        maker.channel.description = "#{@base_uri} - #{@config['title']}"

        maker.items.do_sort = true

        rss_list.each do |rss|
          rss.items.each do |item|
            next if skip?(item)
            new_item = maker.items.new_item
            %w"link title date".each do |attr|
              value = item.__send__(attr)
              value = k(value) if value.is_a?(String)
              new_item.__send__("#{attr}=", value)
            end
          end
        end
      end
    end
  end
end
