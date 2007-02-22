$LOAD_PATH.push File.join(File.dirname(__FILE__), 'lib')
require 'td2planet/version'
Gem::Specification.new do |s|
   s.name = "td2planet"
   s.version = TD2Planet::TD2PLANET_VERSION
   s.date = TD2Planet::TD2PLANET_RELEASE_DATE

   s.author = "Kazuhiro NISHIYAMA"
   s.email = "zn@mbf.nifty.com"
   #s.homepage = "http://rubyforge.org/projects/td2planet/"
   #s.rubyforge_project = "td2planet"

   s.platform = Gem::Platform::RUBY
   s.summary = "planet of ruby, mainly for tdiary"
   s.files = [
     Dir.glob("{bin,lib}/**/*.rb"),
     %w"ChangeLog MIT-LICENSE README README.ja",
     %w"config.yaml",
     Dir.glob("**/templates/*.r{html,xml}"),
   ].flatten.sort
   s.require_path = "lib"
   s.executables = %w"td2planet.rb"
   s.has_rdoc = true
   s.rdoc_options = %w"--charset utf-8 --inline-source --line-numbers --main README"
   s.extra_rdoc_files = %w"README README.ja"
end
