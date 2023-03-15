module DefineRails
  module SensitiveData
    module Encryption

      class Encryptor < ::ActiveRecord::Encryption::Encryptor

        def initialize(
          empty_string_visible_in_db: true,
          store_nil_as_empty_string: true
          )
          @empty_string_visible_in_db = empty_string_visible_in_db
          @store_nil_as_empty_string = store_nil_as_empty_string
        end

        def encrypt(clear_text, **options)
          if clear_text.present?
            super
          elsif clear_text.nil?
            if @store_nil_as_empty_string
              ""
            else
              nil
            end
          elsif clear_text.strip == ""
            if @empty_string_visible_in_db
              ""
            else
              super
            end
          end
        end

        def decrypt(encrypted_text, **options)
          if encrypted_text.present?
            super
          elsif encrypted_text.nil?
            nil
          elsif encrypted_text.strip == ""
            if @store_nil_as_empty_string
              nil
            elsif @empty_string_visible_in_db
              ""
            else
              # Let it bomb!
              super
            end
          end
        end

      end

    end
  end
end
