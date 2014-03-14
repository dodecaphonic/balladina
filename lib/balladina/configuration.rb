module Balladina
  class Configuration
    include Singleton

    attr_accessor :mixdowns_path, :public_mixdowns_path, :chunks_path

    def self.load(config_file)
      config = self.instance

      YAML.load(open(config_file)).each do |key, value|
        config.public_send "#{key}=", value
      end

      config
    end
  end
end
