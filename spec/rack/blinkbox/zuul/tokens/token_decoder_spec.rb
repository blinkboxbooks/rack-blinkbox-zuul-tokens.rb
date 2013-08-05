require_relative "../../../../spec_helper"

describe "A Rack app using Zuul TokenDecoder" do
  include Rack::Test::Methods

  def app
    @app ||= App.new
  end

  context "with no token" do
    before(:all) do
      get "/"
    end
    describe "the request environment" do
      subject { last_request.env }
      it { should_not have_key_starting_with("zuul.") }
    end
  end

  context "with a well-formed signed/encrypted token" do
    before(:all) do
      claims = {
        "sub" => "urn:blinkbox:zuul:user:123",
        "exp" => (Time.now + 1800).to_i,
        "jti" => "urn:blinkbox:zuul:access-token:4857",
        "bb/cid" => "urn:blinkbox:zuul:client:38"
      }
      puts File.expand_path("./")
      signer = Sandal::Sig::ES256.new(File.read("./spec/keys/test-sig/private.pem"))
      encrypter = Sandal::Enc::A128GCM.new(Sandal::Enc::Alg::RSA_OAEP.new(File.read("./spec/keys/test-enc/public.pem")))
      jws_token = Sandal.encode_token(claims, signer, { "kid" => "test-sig" })
      jwe_token = Sandal.encrypt_token(jws_token, encrypter, { "kid" => "test-enc", "cty" => "JWT" })
      get "/", nil, { "HTTP_AUTHORIZATION" => "Bearer #{jwe_token}" }
    end
    describe "the request environment" do
      subject { last_request.env }
      it { should have_key("zuul.access_token") }
      it { should_not have_key("zuul.error") }
      its(["zuul.user_guid"]) { should eq("urn:blinkbox:zuul:user:123") }
      its(["zuul.user_id"]) { should eq("123") }
      its(["zuul.client_guid"]) { should eq("urn:blinkbox:zuul:client:38") }
      its(["zuul.client_id"]) { should eq("38") }
    end
  end

  context "with a well-formed encrypted but unsigned token" do
    pending
  end

  context "with a well-formed signed but unencrypted token" do
    pending
  end

  context "with a well-formed but unsigned/unencrypted token" do
    before(:all) do
      token = Sandal.encode_token({ "sub" => "urn:blinkbox:zuul:user:123" }, Sandal::Sig::NONE)
      get "/", nil, { "HTTP_AUTHORIZATION" => "Bearer #{token}" }
    end
    describe "the request environment" do
      subject { last_request.env }
      it { should have_key("zuul.access_token") }
      it { should have_key("zuul.error") }
      it { should_not have_key_starting_with("zuul.user") }
      it { should_not have_key_starting_with("zuul.client") }
    end
  end

  context "with an invalidly formed token" do
    before(:all) do
      get "/", nil, { "HTTP_AUTHORIZATION" => "Bearer some.random.invalid.token.value" }
    end
    describe "the request environment" do
      subject { last_request.env }
      it { should have_key("zuul.access_token") }
      it { should have_key("zuul.error") }
      it { should_not have_key_starting_with("zuul.user") }
      it { should_not have_key_starting_with("zuul.client") }
    end
  end

end