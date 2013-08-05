require "rack"
require "sandal"

module Rack
  module Blinkbox
    module Zuul
      # A simple key finder which uses the key identifier to locate keys on the file system.
      class FileKeyFinder

        # Initialises a new file key finder.
        #
        # @param key_dir [String] The directory in which keys are located.
        def initialize(key_dir = "./keys")
          @key_dir = key_dir
        end

        # Loads a key with a specified identifier.
        #
        # @param key_id [String] The key identifier.
        # @param type [Symbol] :public, :private or :symmetric, depending on the required key type.
        # @return [String]
        def key_with_id(key_id, type)
          raise Sandal::InvalidTokenError.new("Unspecified key.") if key_id.nil?
          key_dir = ::File.join(@key_dir, ::File.expand_path(key_id, "/")) # mitigate directory expansion attacks
          key_file = "#{key_dir}/#{type}.pem"
          begin
            ::File.read(key_file) # TODO: Binary read
          rescue
            raise Sandal::InvalidTokenError.new("Unknown key.")
          end
        end

      end
    end
  end
end