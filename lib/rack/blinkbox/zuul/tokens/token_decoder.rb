require "rack"
require "sandal"

module Rack
  module Blinkbox
    module Zuul
      class TokenDecoder

        def initialize(app)
          @app = app
        end

        def call(env)
          access_token = extract_bearer_token(env)
          if access_token
            env["zuul.access_token"] = access_token
            begin
              env["zuul.claims"] = claims = decode_access_token(access_token)
              
              user_guid = claims["sub"]
              env["zuul.user_guid"] = user_guid
              env["zuul.user_id"] = user_guid.match(/\Aurn:blinkbox:zuul:user:(\d+)\Z/)[1]
              env["zuul.user_roles"] = claims["bb/rol"] || []

              client_guid = claims["bb/cid"]
              if client_guid
                env["zuul.client_guid"] = client_guid
                env["zuul.client_id"] = client_guid.match(/\Aurn:blinkbox:zuul:client:(\d+)\Z/)[1]
              end
            rescue => error
              env["zuul.error"] = error
            end
          end
          @app.call(env)   
        end

        private

        def extract_bearer_token(env)
          auth_header = env["HTTP_AUTHORIZATION"]
          return nil if auth_header.nil?
              
          auth_scheme, bearer_token = auth_header.split(" ", 2)
          return nil unless auth_scheme == "Bearer"

          bearer_token
        end

        def decode_access_token(access_token)
          Sandal.decode_token(access_token) do |header|            
            if header["alg"] == Sandal::Sig::ES256::NAME
              key = load_key(header["kid"], :public)
              Sandal::Sig::ES256.new(key)
            elsif header["enc"] == Sandal::Enc::A128GCM::NAME && header["alg"] == Sandal::Enc::Alg::RSA_OAEP::NAME
              key = load_key(header["kid"], :private)
              Sandal::Enc::A128GCM.new(Sandal::Enc::Alg::RSA_OAEP.new(key))
            else
              raise Sandal::TokenError.new("Unsupported signing/encryption method.")
            end
          end
        end

        def load_key(key_id, type)
          raise Sandal::TokenError.new("Unspecified key identifier") if key_id.nil?
          key_dir = "./keys" + ::File.expand_path(key_id, "/")
          key_file = "#{key_dir}/#{type}.pem"
          begin
            ::File.read(key_file)
          rescue
            raise Sandal::TokenError.new("Unknown key.")
          end
        end  

      end
    end
  end
end