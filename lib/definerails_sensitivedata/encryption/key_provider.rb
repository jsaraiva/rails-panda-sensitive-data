module DefineRails
  module SensitiveData
    module Encryption

      class KeyProvider < ::ActiveRecord::Encryption::KeyProvider

        def initialize
          super(
            Array(::ActiveRecord::Encryption.config.primary_key)
              .collect do |password|
                ::DefineRails::SensitiveData::Encryption::Key.derive_from(password)
              end
          )
        end

        def encryption_key
          random__key_salt = ::SecureRandom.alphanumeric(8)
          active_primary_key.with_salt(random__key_salt).tap do |key|
            key.public_tags[:ks] = random__key_salt
            key.public_tags.encrypted_data_key_id = active_primary_key.id \
              if ::ActiveRecord::Encryption.config.store_key_references
          end
        end

        def decryption_keys(encrypted_message)
          if keys = super(encrypted_message)
            if key_salt = encrypted_message.headers[:ks]
              return keys.collect do |k|
                k.with_salt(key_salt)
              end
            end
          end
          []
        end

        private

        def active_primary_key
          @active_primary_key ||= @keys.last
        end

      end

    end
  end
end
