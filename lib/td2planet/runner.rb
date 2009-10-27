# -*- mode: ruby; coding: utf-8 -*-
# vim: set filetype=ruby ts=2 sw=2 sts=2 fenc=utf-8:
#
# copyright (c) 2006, 2007, 2009 Kazuhiro NISHIYAMA

require 'optparse'
require 'td2planet/fetcher'
require 'td2planet/formatter'
require 'td2planet/writer'
require 'yaml'

module TD2Planet
  module_function

  def main(argv=ARGV)
    opts = OptionParser.new
    usage = proc { puts opts; exit(1) }
    opts.banner << " config.yaml"
    @dry_run = false
    opts.on('-n', '--dry-run', 'do not fetch, generate files only') { @dry_run = true }
    opts.on('-h', '--help', 'show this message') { usage.call }
    opts.parse!(argv)
    if argv.empty?
      usage.call
    end
    argv.each do |filename|
      config = YAML.load(File.read(filename))
      run(config)
    end
  end

  def get_formatter_class(formatter_name)
    formatter_class_name = formatter_name.gsub(/(^|_)(.)/) { $2.upcase }
    begin
      require formatter_name
    rescue LoadError
      begin
        require "td2planet/#{formatter_name}"
      rescue LoadError
        raise LoadError, "no such formatter: #{formatter_name}"
      end
    end
    formatter = const_get(formatter_class_name)
  end

  def run(config)
    formatter_name = config['formatter'] || 'default_formatter'
    formatter = get_formatter_class(formatter_name).new(config)

    writer = Writer.new(config, formatter)
    fetcher = Fetcher.new(config['cache_dir'], @dry_run)
    rss_list = fetcher.fetch_all_rss(config['uri'])

    writer.output_html(rss_list)
    writer.output_opml(rss_list)
    writer.output_rss(rss_list)
  end
end
