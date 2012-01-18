# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "printr/version"

Gem::Specification.new do |s|
  s.name        = "printr"
  s.version     = '0.5.0'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Michael Franzl","Jason Martin"]
  s.email       = ["jason@jason-knight-martin.com"]
  s.homepage    = ""
  s.summary     = %q{An engine for interfacing with printers.}
  s.description = %q{This engine allows you to define printers and templates.}

  s.rubyforge_project = "printr"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
