require "sinatra/base"
$:<<File.join(File.dirname(__FILE__), "..", "lib")

require "rack/test"
require "rack/blinkbox/zuul/tokens"
require "sandal"
require "yarjuf"

class App < Sinatra::Base
  use Rack::Blinkbox::Zuul::TokenDecoder
end