# -*- mode: ruby; coding: utf-8 -*-
# vim: set filetype=ruby ts=2 sw=2 sts=2 fenc=utf-8:
#
# copyright (c) 2006, 2007, 2009 Kazuhiro NISHIYAMA

module TD2Planet
  TD2PLANET_VERSION = "0.2.0"
  TD2PLANET_RELEASE_DATE = "2009-10-29"

  # return ruby version string (simulate output of ruby -v)
  def self.ruby_version
    if defined?(RUBY_PATCHLEVEL)
      "ruby #{RUBY_VERSION} (#{RUBY_RELEASE_DATE} patchlevel #{RUBY_PATCHLEVEL}) [#{RUBY_PLATFORM}]"
    else
      "ruby #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) [#{RUBY_PLATFORM}]"
    end
  end

  # return TD2Planet version string
  def self.td2planet_version
    "TD2Planet #{TD2PLANET_VERSION} (#{TD2PLANET_RELEASE_DATE})"
  end

  # return string for meta generator (see templates/layout.rhtml)
  def self.generator
    "#{td2planet_version} / Powered by #{ruby_version}"
  end
end
