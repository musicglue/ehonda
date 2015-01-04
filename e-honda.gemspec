$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'e-honda/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'e-honda'
  s.version     = EHonda::VERSION
  s.authors     = ['Lee Henson']
  s.email       = ['lee.m.henson@gmail.com']
  s.homepage    = 'https://github.com/musicglue/e-honda'
  s.summary     = 'Addons for phstc/shoryuken'
  s.description = 'Addons for phstc/shoryuken'
  s.license     = 'MIT'

  s.files = Dir['{app,bin,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['test/**/*']
  s.require_paths = ['lib']

  s.add_runtime_dependency 'shoryuken'

  s.add_development_dependency 'awesome_print'
  s.add_development_dependency 'bundler', '~> 1.6'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-minitest'
  s.add_development_dependency 'guard-rubocop'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'minitest-focus'
  s.add_development_dependency 'minitest-rg'
  s.add_development_dependency 'minitest-spec-rails'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'rake'
end
