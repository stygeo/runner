require 'active_support'

module Runner
  module Serialization
    module Marshal
      class Serializer
        def self.dump(data)
          ActiveSupport::Base64.encode64(data)
        end
      
        def self.load(data)
          Marshal.load(ActiveSupport::Base64.decode64(data))
        end
      end
    end
  end
end