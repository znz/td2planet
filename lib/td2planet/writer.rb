# -*- mode: ruby; coding: utf-8 -*-
# vim: set filetype=ruby ts=2 sw=2 sts=2 fenc=utf-8:
#
# copyright (c) 2006, 2007, 2009 Kazuhiro NISHIYAMA

require 'pathname'

module TD2Planet
  class Writer
    def initialize(config, formatter)
      @config = config
      @output_dir ||= Pathname.new(config['output_dir'])
      unless @output_dir.exist?
        @output_dir.mkdir
      end
      @formatter = formatter
    end

    def output_html(rss_list)
      if @config.key?('output_html')
        output_html = @output_dir + @config['output_html']
      else
        output_html = @output_dir + 'index.html'
      end

      output_html.open('wb') do |f|
        f.write(@formatter.to_html(rss_list))
      end
    end

    def output_opml(rss_list)
      output_opml = @output_dir + 'opml.xml'
      output_opml.open('wb') do |f|
        f.write(@formatter.to_opml(rss_list))
      end
    end

    def output_rss(rss_list)
      [
        ['1.0', 'rss10.xml'],
        ['2.0', 'rss20.xml'],
      ].each do |rss_version, basename|
        output_rss = @output_dir + basename
        output_rss.open('wb') do |f|
          f.write(@formatter.to_rss(rss_list, rss_version, basename))
        end
      end
    end
  end
end
