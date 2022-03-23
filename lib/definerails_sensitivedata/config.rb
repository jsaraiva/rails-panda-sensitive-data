module DefineRails
  module SensitiveData

    class << self
      def configure
        yield config
      end

      def config
        @_config ||= Config.new
      end
    end

    class Config
      attr_accessor :codebase_encryption_key

      def initialize
        @codebase_encryption_key =
          if Rails.env.production?
            'a78683f4'
          else
            '286f6ec0'
          end
      end
    end
  end
end
