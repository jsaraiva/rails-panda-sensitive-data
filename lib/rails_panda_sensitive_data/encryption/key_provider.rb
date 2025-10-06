# frozen_string_literal: true

module RailsPanda
  module SensitiveData
    module Encryption
      class KeyProvider
        def encryption_key
          random__key_salt = ::SecureRandom.alphanumeric(8).freeze
          active_primary_key.with_salt(random__key_salt).tap do |key|
            key.public_tags[:ks] = random__key_salt
            key.public_tags.encrypted_data_key_id = active_primary_key.id \
              if ::ActiveRecord::Encryption.config.store_key_references
          end
        end

        def decryption_keys(encrypted_message)
          keys_for_decryption =
            if ::ActiveRecord::Encryption.config.store_key_references &&
                encrypted_message.headers.encrypted_data_key_id
              keys_grouped_by_id[encrypted_message.headers.encrypted_data_key_id]
            else
              primary_keys_to_use
            end

          key_salt = encrypted_message.headers[:ks]

          if keys_for_decryption && key_salt
            return keys_for_decryption.collect do |k|
              k.with_salt(key_salt)
            end
          end
          []
        end

        private

        def active_primary_key
          @active_primary_key ||= primary_keys_to_use.last
        end

        def keys_grouped_by_id
          @keys_grouped_by_id ||= primary_keys_to_use.group_by(&:id)
        end

        def primary_keys_to_use
          @primary_keys_to_use ||=
            Array(::ActiveRecord::Encryption.config.primary_key)
              .collect do |password|
                ::RailsPanda::SensitiveData::Encryption::Key.derive_from(password)
              end
        end
      end
    end
  end
end
