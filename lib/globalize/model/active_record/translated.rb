module Globalize
  module Model
    module ActiveRecord
      module Translated
        def self.included(base)
          base.extend ActMethods   
          base.class_eval do
            def to_xml_with_translated_fields(args={})
              to_xml_without_translated_fields args.merge(:methods=>self.class.options) 
            end
          end
          base.alias_method_chain :to_xml, :translated_fields
        end

        module ActMethods
          def translates(*attr_names)
            options = attr_names.extract_options!
            options[:translated_attributes] = attr_names

            # Only set up once per class
            unless included_modules.include? InstanceMethods
              class_inheritable_accessor :globalize_options
              include InstanceMethods

              proxy_class = Globalize::Model::ActiveRecord.create_proxy_class(self)
              has_many :globalize_translations, :class_name => proxy_class.name do
                def by_locales(locales)
                  find :all, :conditions => { :locale => locales.map(&:to_s) }
                end
              end
               
              named_scope :available_in_locale, lambda { 
                { :joins=>:globalize_translations,
                   :conditions=>["#{proxy_class.table_name}.locale=?", ::I18n.locale] }
              }
              after_save do |record|
                record.globalize.update_translations!
              end
            end

            self.globalize_options = options
            Globalize::Model::ActiveRecord.define_accessors(self, attr_names)
          end
        end

        module InstanceMethods
          def globalize
            @globalize ||= Adapter.new self
          end      
          

        end
      end
    end
  end
end