require "rack"
require "sandal"
require "rack/blinkbox/zuul/tokens/file_key_finder"

module Rack
  module Blinkbox
    module Zuul
      # Rack middleware for decoding blinkbox Zuul authentication tokens.
      class TokenDecoder

        # Initialises a new token decoder.
        #
        # @param app [??] The Rack application.
        # @param key_finder [#key_with_id] The class that is used to find
        #
        def initialize(app, key_finder = nil)
          @app = app
          @key_finder = key_finder || FileKeyFinder.new("./keys")
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
              key = @key_finder.key_with_id(header["kid"], :public)
              Sandal::Sig::ES256.new(key)
            elsif header["enc"] == Sandal::Enc::A128GCM::NAME && header["alg"] == Sandal::Enc::Alg::RSA_OAEP::NAME
              key = @key_finder.key_with_id(header["kid"], :private)
              Sandal::Enc::A128GCM.new(Sandal::Enc::Alg::RSA_OAEP.new(key))
            else
              raise Sandal::UnsupportedTokenError.new("Unsupported signing/encryption method.")
            end
          end
        end

      end
    end
  end
end