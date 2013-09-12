# -*- mode: ruby; coding: utf-8 -*-
# vim: set filetype=ruby ts=2 sw=2 sts=2:
#
# copyright (c) 2006, 2007, 2009 Kazuhiro NISHIYAMA

require 'erb'
require 'pathname'
require 'rss'
require 'uri'

module TD2Planet
  class Fetcher
    def initialize(cache_dir, dry_run=false, user_agent="td2planet")
      @cache_dir = Pathname.new(cache_dir)
      unless @cache_dir.exist?
        @cache_dir.mkdir
      end
      @dry_run = dry_run
      @user_agent = user_agent
    end

    def fetch_all_rss(uris)
      rss_list = []
      uris.each do |uri|
        cache_file = @cache_dir + ERB::Util.u(uri)
        if @dry_run
          puts "use cache: #{cache_file}"
          text = cache_file.read
        else
          text = nil
          begin
            puts "fetch: #{uri}"
            text = URI.parse(uri).read("User-Agent" => @user_agent)
          rescue Timeout::Error
            # fallback
            puts "ERROR: timeout #{uri}"
            text = cache_file.read
          rescue Exception
            puts "ERROR: #{$!} (#{$!.class}) on #{uri}"
            next
          else
            if text.status[0] == '200' && /rss/ =~ text
              cache_file.open('wb'){|f| f.write(text) }
            else
              # fallback
              puts "ERROR: fetch failed #{uri} #{text.status}"
              text = cache_file.read
            end
          end
        end
        text = fixup_rss(text)
        rss_list << RSS::Parser.parse(text, false)
      end
      rss_list
    end

    # euc-jp may fail to parse
    def fixup_rss(text)
      text.sub(/\bencoding="euc-jp"/ni, 'encoding="euc-jp-ms"')
    end
  end
end
