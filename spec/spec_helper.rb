require "sinatra/base"
$:<<File.join(File.dirname(__FILE__), "..", "lib")

require "rack/test"
require "rack/blinkbox/zuul/tokens"
require "sandal"

class App < Sinatra::Base
  use Rack::Blinkbox::Zuul::TokenDecoder, Rack::Blinkbox::Zuul::FileKeyFinder.new("./spec/keys")
end

class Hash
  def has_key_starting_with?(prefix)
    keys.any? { |k| k =~ /^#{::Regexp.escape(prefix)}/ }
  end
end