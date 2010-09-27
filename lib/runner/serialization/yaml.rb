module Runner
  module Serialization
    module Yaml
      class Serializer
        def self.dump(data)
          data.to_yaml
        end
      
        def self.load(data)
          Yaml.load data
        end
      end
    end
  end
end