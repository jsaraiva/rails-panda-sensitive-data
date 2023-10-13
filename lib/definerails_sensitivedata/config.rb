module DefineRails
  module SensitiveData
    class Config
    end

    class << self
      def configure
        yield config
      end

      def config
        @config ||= Config.new
      end
    end
  end
end
