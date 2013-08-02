require_relative "../../../../spec_helper"

class Hash
  def has_key_starting_with?(prefix)
    keys.any? { |k| k =~ /^#{::Regexp.escape(prefix)}/ }
  end
end

describe "A Rack app using Zuul TokenDecoder" do
  include Rack::Test::Methods

  def app
    @app ||= App.new
  end

  context "with no token" do
    describe "the request environment" do
      subject do
        get "/"
        last_request.env
      end
      it { should_not have_key_starting_with("zuul.") }
    end
  end

  context "with a valid but unsigned token" do
    describe "the request environment" do
      subject do
        token = Sandal.encode_token({ "sub" => "urn:blinkbox:zuul:user:123" }, Sandal::Sig::NONE)
        get "/", nil, { "HTTP_AUTHORIZATION" => "Bearer #{token}" }
        last_request.env
      end
      it { should have_key("zuul.access_token") }
      it { should have_key("zuul.error") }
      it { should_not have_key_starting_with("zuul.user") }
      it { should_not have_key_starting_with("zuul.client") }
    end
  end

  context "with an invalid token" do
    describe "the request environment" do
      subject do
        get "/", nil, { "HTTP_AUTHORIZATION" => "Bearer some.random.invalid.token.value" }
        last_request.env
      end
      it { should have_key("zuul.access_token") }
      it { should have_key("zuul.error") }
      it { should_not have_key_starting_with("zuul.user") }
      it { should_not have_key_starting_with("zuul.client") }
    end
  end

end