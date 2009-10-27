# -*- mode: ruby; coding: utf-8 -*-
# vim: set filetype=ruby ts=2 sw=2 sts=2 fenc=utf-8:
#
# copyright (c) 2006, 2007, 2009 Kazuhiro NISHIYAMA

require 'td2planet/formatter'

module TD2Planet
  class DefaultFormatter < Formatter
    def initialize(config)
      super
      unless @config.key?('filter')
        @config['filter'] = 'true'
      end
    end

    def skip?(item)
      eval(@config['filter']) or too_old?(item)
    end
  end
end
