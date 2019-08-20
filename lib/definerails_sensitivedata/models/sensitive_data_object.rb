module DefineRails
  module SensitiveData
    module Models

      module SensitiveDataObject

        module ActiveRecord
          extend ActiveSupport::Concern

          included do
            before_save :set_encryption_key
          end

          def set_encryption_key
            if self.has_attribute? :encryption_key
              # 8 chars
              self.encryption_key =
                SecureRandom.hex(4) unless self.encryption_key.present?
            end
          end

          def sensitive_data_encryption_key
            set_encryption_key
            the_key =
              self.encryption_key +
              ::DefineRails::SensitiveData.application_sensitive_data_encryption_key
          end

          class_methods do

            def add_encrypted_attribute(attribute_name, opts = {})
              attr_encryptor attribute_name, key: :sensitive_data_encryption_key,
                                             marshal: true
            end

            def add_sensitive_attribute_accessors(attribute_name, opts = {})
              in_attribute = opts[:in] || :sensitive_data

              unless respond_to? in_attribute
                attr_encryptor in_attribute, key: :sensitive_data_encryption_key,
                                             marshal: true
              end

              define_method attribute_name do
                the_attribute_value = self.send in_attribute

                the_attribute_value&.dig(attribute_name)
              end

              define_method "#{ attribute_name }=" do |the_value|
                the_attribute_value = self.send in_attribute

                the_attribute_value = {} unless the_attribute_value.present?
                the_attribute_value[attribute_name] = the_value
                self.send "#{in_attribute}=", the_attribute_value
                # self.send "#{in_attribute}_will_change!"
              end

            end

          end

        end


        module Mongoid
          extend ActiveSupport::Concern

          included do
            extend ::AttrEncrypted

            before_save :set_encryption_key

            field :encryption_key, type: String
          end

          def set_encryption_key
            # 8 chars
            self.encryption_key =
              SecureRandom.hex(4) unless self.encryption_key.present?
          end

          def sensitive_data_encryption_key
            set_encryption_key
            the_key =
              self.encryption_key +
              ::DefineRails::SensitiveData.application_sensitive_data_encryption_key
          end

          class_methods do

            def add_encrypted_attribute(attribute_name, opts = {})
              db_attribute_name = attribute_name
              attribute_name = opts[:as] || attribute_name

              self.send :field, "encrypted_#{db_attribute_name}", as: "encrypted_#{attribute_name}",
                                                                  type: String
              self.send :field, "encrypted_#{db_attribute_name}_iv", as: "encrypted_#{attribute_name}_iv",
                                                                     type: String

              self.send :attr_encryptor, attribute_name, key: :sensitive_data_encryption_key,
                                                         marshal: true,
                                                         encode: true
            end

            def add_sensitive_attribute_accessors(attribute_name, opts = {})
              in_attribute = opts[:in] || :sensitive_data
              db_in_attribute = opts[:in_db] || in_attribute

              unless self.respond_to? :sensitive_data
                self.send :field, "encrypted_#{db_in_attribute}", as: "encrypted_#{in_attribute}",
                                                                  type: String
                self.send :field, "encrypted_#{db_in_attribute}_iv", as: "encrypted_#{in_attribute}_iv",
                                                                     type: String

                self.send :attr_encryptor, in_attribute, key: :sensitive_data_encryption_key,
                                                         marshal: true,
                                                         encode: true
              end

              self.send(:define_method, attribute_name) do
                the_attribute_value = self.send in_attribute

                the_attribute_value&.dig(attribute_name)
              end

              self.send(:define_method, "#{ attribute_name }=") do |the_value|
                the_attribute_value = self.send in_attribute

                the_attribute_value = {} unless the_attribute_value.present?
                the_attribute_value[attribute_name] = the_value
                self.send "#{in_attribute}=", the_attribute_value
                # self.send "#{in_attribute}_will_change!"
              end

            end

          end

        end

      end
    end
  end
end
