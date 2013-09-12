#! /usr/bin/ruby
# -*- mode: ruby; coding: utf-8 -*-
# vim: set filetype=ruby ts=2 sw=2 sts=2:
#
# copyright (c) 2006, 2007, 2013 Kazuhiro NISHIYAMA

if RUBY_VERSION < "1.9"
  $KCODE = "u"
end

require 'td2planet/runner'
require 'td2planet/version'

TD2Planet.main
