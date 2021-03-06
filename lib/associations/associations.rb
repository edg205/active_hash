module ActiveHash
  module Associations

    module ActiveRecordExtensions

      def belongs_to_active_hash(association_id, options = {})
        options = {
          :class_name => association_id.to_s.camelize,
          :foreign_key => association_id.to_s.foreign_key,
          :primary_key => "id",
          :shortcuts => []
        }.merge(options)
        options[:shortcuts] = [options[:shortcuts]] unless options[:shortcuts].kind_of?(Array)

        define_method(association_id) do
          options[:class_name].constantize.send("find_by_#{options[:primary_key]}", send(options[:foreign_key]))
        end

        define_method("#{association_id}=") do |new_value|
          send "#{options[:foreign_key]}=", new_value ? new_value.id : nil
        end

        options[:shortcuts].each do |shortcut|
          define_method("#{association_id}_#{shortcut}") do
            send(association_id).try(shortcut)
          end

          define_method("#{association_id}_#{shortcut}=") do |new_value|
            send "#{association_id}=", new_value ? options[:class_name].constantize.send("find_by_#{shortcut}", new_value) : nil
          end
        end

        create_reflection(
            :belongs_to,
            association_id.to_sym,
            options,
            options[:class_name].constantize
            )
      end

    end

    def self.included(base)
      base.extend Methods
    end

    module Methods
      def has_many(association_id, options = {})

        define_method(association_id) do
          options = {
            :class_name => association_id.to_s.classify,
            :foreign_key => self.class.to_s.foreign_key
          }.merge(options)

          klass = options[:class_name].constantize

          if klass.respond_to?(:scoped)
            klass.scoped(:conditions => {options[:foreign_key] => id})
          else
            klass.send("find_all_by_#{options[:foreign_key]}", id)
          end
        end
      end

      def has_one(association_id, options = {})
        define_method(association_id) do
          options = {
            :class_name => association_id.to_s.classify,
            :foreign_key => self.class.to_s.foreign_key
          }.merge(options)

          scope = options[:class_name].constantize

          if scope.respond_to?(:scoped) && options[:conditions]
            scope = scope.scoped(:conditions => options[:conditions])
          end
          scope.send("find_by_#{options[:foreign_key]}", id)
        end
      end

      def belongs_to(association_id, options = {})

        options = {
          :class_name => association_id.to_s.classify,
          :foreign_key => association_id.to_s.foreign_key
        }.merge(options)

        field options[:foreign_key].to_sym

        define_method(association_id) do
          options[:class_name].constantize.find_by_id(send(options[:foreign_key]))
        end

        define_method("#{association_id}=") do |new_value|
          attributes[options[:foreign_key].to_sym] = new_value ? new_value.id : nil
        end

      end
    end

  end
end
