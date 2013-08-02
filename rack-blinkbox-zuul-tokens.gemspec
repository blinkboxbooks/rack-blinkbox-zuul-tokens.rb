# -*- encoding: utf-8 -*-
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rack/blinkbox/zuul/tokens/version"

Gem::Specification.new do |s|
  s.name          = "rack-blinkbox-zuul-tokens"
  s.version       = Rack::Blinkbox::Zuul::Tokens::VERSION
  s.authors       = ["Greg Beech", "JP Hastings-Spital"]
  s.email         = ["greg@blinkbox.com", "jphastings@blinkbox.com"]
  s.description   = %q{Automatically processes Zuul authorisation tokens on Rack apps}
  s.summary       = %q{blinkbox books authentication for rack apps}
  s.homepage      = ""

  s.files         = `git ls-files`.split($/)
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_dependency "rack"
  s.add_dependency "sandal", "~> 0.5", ">= 0.5.1"

  s.add_development_dependency "rack-test"
  s.add_development_dependency "rspec", "~> 2.0"
  s.add_development_dependency "sinatra"
  s.add_development_dependency "yarjuf"
end
