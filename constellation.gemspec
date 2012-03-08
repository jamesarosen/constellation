# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = "constellation"
  s.version     = '0.0.1'
  s.authors     = ["James A. Rosen"]
  s.email       = ["james.a.rosen@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Load configuration settings}
  s.description = %q{Load configuration settings from ENV, dotfiles, and gems}

  s.files         = Dir.glob('lib/**/*') + %w(README.md)
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'multi_json'

  s.add_development_dependency "rspec"
  s.add_development_dependency 'fakefs'
  s.add_development_dependency 'mocha'
end
