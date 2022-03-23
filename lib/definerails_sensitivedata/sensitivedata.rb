require 'definerails_sensitivedata/config'

module DefineRails
  module SensitiveData

    class << self
      def application_sensitive_data_encryption_key
        unless @_sensitive_data_encryption_key.present?

          # 16 chars
          raise unless \
            env_encryption_key = ENV['SENSITIVE_DATA_ENCRYPTION_KEY']

          # 8 chars
          codebase_encryption_key =
            ::DefineRails::SensitiveData.config.codebase_encryption_key
          unless codebase_encryption_key.present?
            codebase_encryption_key =
              if Rails.env.production?
                'a78683f4'
              else
                '286f6ec0'
              end
          end

          # 24 chars
          @_sensitive_data_encryption_key =
            codebase_encryption_key + env_encryption_key
        end

        @_sensitive_data_encryption_key
      end
    end
  end
end
