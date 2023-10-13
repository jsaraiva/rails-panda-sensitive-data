module ActiveRecord
  module Encryption

    class EncryptedAttributeType

      private

      def serialize_with_current(value)
        casted_value = cast_type.serialize(value)
        casted_value = casted_value&.downcase if downcase?
        encrypt(casted_value.to_s)
      end

      def decrypt(value)
        with_context do
          encryptor.decrypt(value, **decryption_options)
        end
      rescue ActiveRecord::Encryption::Errors::Base => e
        if previous_types_without_clean_text.blank?
          handle_deserialize_error(e, value)
        else
          try_to_deserialize_with_previous_encrypted_types(value)
        end
      end

    end

  end
end
