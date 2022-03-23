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
              nil_value_visible = true if opts.delete(:nil_value_visible)
              empty_value_visible = true if opts.delete(:empty_value_visible)
              treat_nil_as_empty_value = true unless opts.delete(:treat_nil_as_empty_value) == false

              attr_encryptor(
                attribute_name,
                key: :sensitive_data_encryption_key,
                marshal: true,
                allow_empty_value: true,
                **opts
              )

              encryptor_getter_method_name = "__encryptor_#{ attribute_name }"
              encryptor_setter_method_name = "__encryptor_#{ attribute_name }="
              mem_value_attr = "@#{ attribute_name }"

              alias_method encryptor_getter_method_name, attribute_name
              alias_method encryptor_setter_method_name, "#{ attribute_name }="

              encrypted_attribute_name =
                (
                  if opts[:attribute]
                    opts[:attribute]
                  else
                    [
                      (opts[:prefix] || 'encrypted_'),
                      attribute_name,
                      (opts[:suffix] || '')
                    ].join
                  end
                ).to_sym

              define_method attribute_name do
                mem_value = instance_variable_get(mem_value_attr)
                return mem_value if mem_value

                db_value = send(encrypted_attribute_name)

                if nil_value_visible && db_value.nil?
                  return '' if treat_nil_as_empty_value
                  return nil
                end

                if empty_value_visible && db_value == ''
                  return ''
                end

                send(encryptor_getter_method_name)
              end

              define_method "#{ attribute_name }=" do |the_value|
                encrypted_attribute_name__set = "#{encrypted_attribute_name}="
                encrypted_attribute_iv_name__set = "#{encrypted_attribute_name}_iv="

                if nil_value_visible && the_value.nil?

                  if treat_nil_as_empty_value
                    send(encrypted_attribute_name__set, '')
                    send(encrypted_attribute_iv_name__set, '')
                    instance_variable_set(mem_value_attr, '')
                    return ''
                  end

                  send(encrypted_attribute_name__set, nil)
                  send(encrypted_attribute_iv_name__set, nil)
                  instance_variable_set(mem_value_attr, nil)
                  return nil
                end

                if empty_value_visible && the_value == ''
                  send(encrypted_attribute_name__set, '')
                  send(encrypted_attribute_iv_name__set, '')
                  instance_variable_set(mem_value_attr, '')
                  return ''
                end

                send(encryptor_setter_method_name, the_value)
              end
            end

            def add_sensitive_attribute_accessors(attribute_name, opts = {})
              in_attribute = opts.delete(:in) || :sensitive_data

              unless respond_to? in_attribute
                attr_encryptor(
                  in_attribute,
                  key: :sensitive_data_encryption_key,
                  marshal: true,
                  allow_empty_value: true,
                  **opts
                )
              end

              define_method attribute_name do
                self.send(in_attribute)&.dig(attribute_name)
              end

              define_method "#{ attribute_name }=" do |the_value|
                the_attribute_value = self.send(in_attribute) || {}

                if the_value.nil?
                  the_attribute_value.delete attribute_name
                else
                  the_attribute_value[attribute_name] = the_value
                end

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
              nil_value_visible = true if opts.delete(:nil_value_visible)
              empty_value_visible = true if opts.delete(:empty_value_visible)
              treat_nil_as_empty_value = true unless opts.delete(:treat_nil_as_empty_value) == false

              prefix = opts[:prefix] || 'encrypted_'
              suffix = opts[:suffix] || ''

              db_attribute_name = [ prefix, attribute_name, suffix ].join

              attribute_name = opts.delete(:as) || attribute_name

              field_name = opts[:attribute] || [ prefix, attribute_name, suffix ].join

              self.send :field, db_attribute_name,
                as: field_name,
                type: String
              self.send :field, "#{db_attribute_name}_iv",
                as: "#{field_name}_iv",
                type: String

              self.send(:attr_encryptor, attribute_name,
                key: :sensitive_data_encryption_key,
                marshal: true,
                encode: true,
                allow_empty_value: true,
                **opts
              )

              encryptor_getter_method_name = "__encryptor_#{ attribute_name }"
              encryptor_setter_method_name = "__encryptor_#{ attribute_name }="
              mem_value_attr = "@#{ attribute_name }"

              alias_method encryptor_getter_method_name, attribute_name
              alias_method encryptor_setter_method_name, "#{ attribute_name }="

              define_method attribute_name do
                mem_value = instance_variable_get(mem_value_attr)
                return mem_value if mem_value

                db_value = send(field_name)

                if nil_value_visible && db_value.nil?
                  return '' if treat_nil_as_empty_value
                  return nil
                end

                if empty_value_visible && db_value == ''
                  return ''
                end

                send(encryptor_getter_method_name)
              end

              define_method "#{ attribute_name }=" do |the_value|
                encrypted_attribute_name__set = "#{field_name}="
                encrypted_attribute_iv_name__set = "#{field_name}_iv="

                if nil_value_visible && the_value.nil?

                  if treat_nil_as_empty_value
                    send(encrypted_attribute_name__set, '')
                    send(encrypted_attribute_iv_name__set, '')
                    instance_variable_set(mem_value_attr, '')
                    return ''
                  end

                  send(encrypted_attribute_name__set, nil)
                  send(encrypted_attribute_iv_name__set, nil)
                  instance_variable_set(mem_value_attr, nil)
                  return nil
                end

                if empty_value_visible && the_value == ''
                  send(encrypted_attribute_name__set, '')
                  send(encrypted_attribute_iv_name__set, '')
                  instance_variable_set(mem_value_attr, '')
                  return ''
                end

                send(encryptor_setter_method_name, the_value)
              end
            end

            def add_sensitive_attribute_accessors(attribute_name, opts = {})
              in_attribute = opts.delete(:in) || :sensitive_data
              db_in_attribute = opts.delete(:in_db) || in_attribute

              unless self.respond_to? :sensitive_data
                self.send :field, "encrypted_#{db_in_attribute}",
                  as: "encrypted_#{in_attribute}",
                  type: String
                self.send :field, "encrypted_#{db_in_attribute}_iv",
                  as: "encrypted_#{in_attribute}_iv",
                  type: String

                self.send(:attr_encryptor, in_attribute,
                  key: :sensitive_data_encryption_key,
                  marshal: true,
                  encode: true,
                  allow_empty_value: true,
                  **opts
                )
              end

              self.send(:define_method, attribute_name) do
                self.send(in_attribute)&.dig(attribute_name)
              end

              self.send(:define_method, "#{ attribute_name }=") do |the_value|
                the_attribute_value = self.send(in_attribute) || {}

                if the_value.nil?
                  the_attribute_value.delete attribute_name
                else
                  the_attribute_value[attribute_name] = the_value
                end

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
