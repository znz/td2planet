#--
# -*- mode: ruby; coding: utf-8 -*-
# vim: set filetype=ruby ts=2 sw=2 sts=2 fenc=utf-8:
#
# copyright (c) 2006, 2007 Kazuhiro NISHIYAMA
#++

require 'td2planet/formatter'

module TD2Planet
  class SampleFormatter < Formatter
    def spam?(item)
      if /ツッコミ/ =~ k(item.title) &&
          /casino/ =~ item.dc_creator &&
          /casino/ =~ item.description
        true
      else
        false
      end
    end

    def skip?(item)
      spam?(item) or too_old?(item)
    end
  end
end
