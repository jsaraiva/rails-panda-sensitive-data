module DefineRails
  module SensitiveData
    class Config
    end

    class << self
      def configure
        yield config
      end

      def config
        @_config ||= Config.new
      end
    end
  end
end
