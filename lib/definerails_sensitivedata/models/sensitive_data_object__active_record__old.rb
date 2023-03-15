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
            if has_attribute? :encryption_key
              _encryption_key = encryption_key
              if _encryption_key.nil? || _encryption_key == ""
                # 8 chars
                self.encryption_key = SecureRandom.hex(4)
              end
            end
          end

          def sensitive_data_encryption_key
            set_encryption_key
            the_key =
              encryption_key +
              ::DefineRails::SensitiveData.application_sensitive_data_encryption_key
          end

          def save(**options)
            super.tap do |result|
              if result
                self.class.__registered_encrypted_attributes&.each do |attr_name|
                  instance_variable_set(
                    "@#{attr_name}_in_database",
                    send(attr_name)
                  )
                end
              end
            end
          end

          def save!(**options)
            super.tap do
              self.class.__registered_encrypted_attributes&.each do |attr_name|
                instance_variable_set(
                  "@#{attr_name}_in_database",
                  send(attr_name)
                )
              end
            end
          end

          class_methods do

            attr_reader :__registered_encrypted_attributes

            def add_encrypted_attribute(attribute_name, opts = {})
              treat_nil_as_empty_value =
                opts.delete(:treat_nil_as_empty_value) ? true : false

              empty_value_visible_in_db =
                opts.delete(:empty_value_visible_in_db) ? true : false

              nil_value_visible_in_db =
                (opts.delete(:nil_value_visible_in_db) ? true : false) ||
                (treat_nil_as_empty_value && empty_value_visible_in_db)

              attr_encryptor(
                attribute_name,
                key: :sensitive_data_encryption_key,
                marshal: true,
                allow_empty_value: true,
                **opts
              )

              (@__registered_encrypted_attributes ||= []).tap do |ary|
                ary << attribute_name
                ary.uniq!
              end

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
                    prefix = opts[:prefix] || "encrypted_"
                    suffix = opts[:suffix] || ""

                    [ prefix, attribute_name, suffix ].join
                  end
                ).to_sym

              attribute_name_in_database =
                "#{attribute_name}_in_database".to_sym
              attribute_name_before_last_save =
                "#{attribute_name}_before_last_save".to_sym

              attr_reader attribute_name_in_database
              attr_reader attribute_name_before_last_save
              after_initialize do
                if respond_to?(encrypted_attribute_name)
                  the_original_var_content = send(attribute_name)
                  instance_variable_set(
                    "@#{ attribute_name_before_last_save }",
                    Marshal.load(Marshal.dump(the_original_var_content))
                  )
                  instance_variable_set(
                    "@#{ attribute_name_in_database }",
                    Marshal.load(Marshal.dump(the_original_var_content))
                  )
                end
              end

              define_method "saved_change_to_#{attribute_name}?" do
                send(attribute_name) != send(attribute_name_before_last_save)
              end

              define_method "{attribute_name}_changed?" do
                send(attribute_name) != send(attribute_name_in_database)
              end

              define_method attribute_name do
                unless value = instance_variable_get(mem_value_attr)

                  db_value = send(encrypted_attribute_name)

                  if nil_value_visible_in_db && db_value.nil?
                    return "" if treat_nil_as_empty_value
                    return nil
                  end

                  if empty_value_visible_in_db && db_value == ""
                    return ""
                  end

                  value = send(encryptor_getter_method_name)
                end

                return "" if treat_nil_as_empty_value && value.nil?
                return value
              end

              define_method "#{ attribute_name }=" do |the_value|
                encrypted_attribute_name__set = "#{encrypted_attribute_name}="
                encrypted_attribute_iv_name__set = "#{encrypted_attribute_name}_iv="

                if nil_value_visible_in_db &&
                    the_value.nil? && !treat_nil_as_empty_value
                  send(encrypted_attribute_name__set, nil)
                  send(encrypted_attribute_iv_name__set, nil)
                  instance_variable_set(mem_value_attr, nil)
                  return nil
                end

                if empty_value_visible_in_db &&
                    (
                      the_value == "" ||
                      (treat_nil_as_empty_value && the_value.nil?)
                    )
                  send(encrypted_attribute_name__set, "")
                  send(encrypted_attribute_iv_name__set, "")
                  instance_variable_set(mem_value_attr, "")
                  return ""
                end

                the_value = "" if treat_nil_as_empty_value && the_value.nil?

                send(encryptor_setter_method_name, the_value)
              end
            end

            def add_sensitive_attribute_accessors(attribute_name, opts = {})
              in_attribute = opts.delete(:in) || :sensitive_data
              in_attribute_in_database = "#{in_attribute}_in_database".to_sym
              in_attribute_before_last_save =
                "#{in_attribute}_before_last_save".to_sym

              mem_value_attr = "@#{ in_attribute }"

              attribute_name_in_database =
                "#{attribute_name}_in_database".to_sym
              attribute_name_before_last_save =
                "#{attribute_name}_before_last_save".to_sym

              encrypted_in_attribute_name =
                (
                  if opts[:attribute]
                    opts[:attribute]
                  else
                    prefix = opts[:prefix] || "encrypted_"
                    suffix = opts[:suffix] || ""

                    [ prefix, in_attribute, suffix ].join
                  end
                ).to_sym

              unless respond_to?(in_attribute)
                attr_encryptor(
                  in_attribute,
                  key: :sensitive_data_encryption_key,
                  marshal: true,
                  allow_empty_value: true,
                  **opts
                )

                (@__registered_encrypted_attributes ||= []).tap do |ary|
                  ary << in_attribute
                  ary.uniq!
                end

                attr_reader in_attribute_before_last_save
                attr_reader in_attribute_in_database
                after_initialize do
                  if respond_to?(encrypted_in_attribute_name)
                    the_original_var_content = send(in_attribute)
                    instance_variable_set(
                      "@#{ in_attribute_before_last_save }",
                      Marshal.load(Marshal.dump(the_original_var_content))
                    )
                    instance_variable_set(
                      "@#{ in_attribute_in_database }",
                      Marshal.load(Marshal.dump(the_original_var_content))
                    )
                  end
                end
              end

              define_method "saved_change_to_#{attribute_name}?" do
                send(attribute_name) != send(attribute_name_before_last_save)
              end

              define_method "#{attribute_name}_changed?" do
                send(attribute_name) != send(attribute_name_in_database)
              end

              define_method attribute_name_before_last_save do
                send(in_attribute_before_last_save)
                  .then {|x| x == "" ? nil : x }
                  &.dig(attribute_name)
              end

              define_method attribute_name_in_database do
                send(in_attribute_in_database)
                  .then {|x| x == "" ? nil : x }
                  &.dig(attribute_name)
              end

              define_method attribute_name do
                unless the_hash = instance_variable_get(mem_value_attr)
                  db_value = send(encrypted_in_attribute_name)
                  return nil if db_value.nil? || db_value == ""

                  the_hash = send(in_attribute)
                end
                return nil if the_hash.nil? || the_hash == ""

                the_hash.dig(attribute_name)
              end

              define_method "#{ attribute_name }=" do |the_value|
                unless the_hash = instance_variable_get(mem_value_attr)
                  db_value = send(encrypted_in_attribute_name)
                  the_hash =
                    send(in_attribute) unless db_value.nil? || db_value == ""
                end
                the_hash = {} if the_hash.nil? || the_hash == ""

                if the_value.nil?
                  the_hash.delete attribute_name
                else
                  the_hash[attribute_name] = the_value
                end

                send("#{in_attribute}=", the_hash)
              end
            end
          end
        end
      end
    end
  end
end
