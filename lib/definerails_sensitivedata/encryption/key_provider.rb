module DefineRails
  module SensitiveData
    module Encryption

      class KeyProvider

        def encryption_key
          random__key_salt = ::SecureRandom.alphanumeric(8)
          active_primary_key.with_salt(random__key_salt).tap do |key|
            key.public_tags[:ks] = random__key_salt
            key.public_tags.encrypted_data_key_id = active_primary_key.id \
              if ::ActiveRecord::Encryption.config.store_key_references
          end
        end

        def decryption_keys(encrypted_message)
          _keys =
            if ::ActiveRecord::Encryption.config.store_key_references &&
               encrypted_message.headers.encrypted_data_key_id
              keys_grouped_by_id[encrypted_message.headers.encrypted_data_key_id]
            else
              _primary_keys
            end

          key_salt = encrypted_message.headers[:ks]

          if _keys && key_salt
            return _keys.collect do |k|
              k.with_salt(key_salt)
            end
          end
          []
        end

        private

        def active_primary_key
          @active_primary_key ||= _primary_keys.last
        end

        def keys_grouped_by_id
          @keys_grouped_by_id ||= _primary_keys.group_by(&:id)
        end

        def _primary_keys
          @keys ||=
          Array(::ActiveRecord::Encryption.config.primary_key)
            .collect do |password|
              ::DefineRails::SensitiveData::Encryption::Key.derive_from(password)
            end
        end

      end

    end
  end
end
