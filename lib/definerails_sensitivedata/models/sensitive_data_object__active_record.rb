module DefineRails
  module SensitiveData
    module Models
      module SensitiveDataObject
        module ActiveRecord
          extend ActiveSupport::Concern

          class_methods do

            def encrypts(*attributes, **options)
              return if attributes.blank?

              encryptor = options.delete(:encryptor)
              key_provider = options.delete(:key_provider)
              key = options.delete(:key)

              empty_string_visible_in_db =
                options.delete(:empty_string_visible_in_db) != false
              store_nil_as_empty_string =
                options.delete(:store_nil_as_empty_string) != false

              if key.nil?
                key_provider ||=
                  ::DefineRails::SensitiveData::Encryption::KeyProvider.new
              end

              encryptor ||=
                ::DefineRails::SensitiveData::Encryption::Encryptor.new(
                  empty_string_visible_in_db:,
                  store_nil_as_empty_string:
                )

              super(
                *attributes,
                encryptor:,
                key_provider:,
                key:,
                **options
              )
            end

            def has_sensitive_data(*attributes, **options)
              return if attributes.blank?

              store_empty_as_nil = options.delete(:store_empty_as_nil) != false

              in_attribute = options.delete(:in)&.to_sym || :sensitive_data

              unless @__has_registered_sensitive_data_encrypted_attribute
                serialize(in_attribute, type: Hash, coder: YAML)
                encrypts(in_attribute, **options)
                @__has_registered_sensitive_data_encrypted_attribute = true
              end

              attributes.each do |attribute_name|
                attribute_name = attribute_name.to_sym

                define_method attribute_name do
                  the_hash = send(in_attribute)
                  the_hash.dig(attribute_name) if the_hash.present?
                end

                define_method "#{ attribute_name }=" do |the_value|
                  the_hash = send(in_attribute)
                  the_hash = {} if the_hash.blank?

                  if the_value.nil?
                    the_hash.delete attribute_name
                  else
                    the_hash[attribute_name] = the_value
                  end

                  send("#{in_attribute}=", the_hash)
                end

                attribute_name_in_database =
                  "#{attribute_name}_in_database".to_sym
                attribute_name_before_last_save =
                  "#{attribute_name}_before_last_save".to_sym

                define_method attribute_name_before_last_save do
                  send("#{in_attribute}_before_last_save")
                    .then {|x| x.blank? ? nil : x }
                    &.dig(attribute_name)
                end

                define_method attribute_name_in_database do
                  send("#{in_attribute}_in_database")
                    .then {|x| x.blank? ? nil : x }
                    &.dig(attribute_name)
                end

                define_method "saved_change_to_#{ attribute_name }?" do
                  send(attribute_name) != send(attribute_name_before_last_save)
                end

                define_method "#{attribute_name}_changed?" do
                  send(attribute_name) != send(attribute_name_in_database)
                end

              end
            end
          end
        end
      end
    end
  end
end
