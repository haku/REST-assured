# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'rest-assured/version'

Gem::Specification.new do |s|
  s.name                  = "rest-assured"
  s.version               = RestAssured::VERSION
  s.platform              = Gem::Platform::RUBY
  s.authors               = ['Artem Avetisyan']
  s.email                 = ['artem.avetisyan@bbc.co.uk']
  s.homepage              = "https://github.com/BBC/rest-assured"
  s.summary               = %q{Real stubs and spies for HTTP(S) services}
  #s.description          = %q{TODO: Write a gem description}

  s.rubyforge_project     = "rest-assured"
  s.required_ruby_version = '>= 1.8.7'

  s.files                 = `git ls-files`.split("\n")
  s.test_files            = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables           = ['rest-assured']
  s.require_paths         = ['lib']

  s.add_dependency 'sinatra', '~> 1.3.2'
  s.add_dependency 'childprocess', '~> 0.3.0'
  s.add_dependency 'sinatra-flash'
  s.add_dependency 'haml', '>= 3.1.3'
  s.add_dependency 'activerecord', '~> 3.2.0'
  s.add_dependency 'activeresource', '~> 3.2.0'
  s.add_dependency 'json'
  s.add_dependency 'erubis'
end

