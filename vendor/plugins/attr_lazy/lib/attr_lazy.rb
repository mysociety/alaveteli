# Taken from here, initial code at top (the refactoring doesn't work).
# http://refactormycode.com/codes/219-activerecord-lazy-attribute-loading-plugin-for-rails

module AttrLazy
  
  def self.included(base_class)
    base_class.extend(ClassMethods)
  end
  
  module ClassMethods
    def attr_lazy(*parameters)
      columns = parameters
      cattr_accessor :attr_lazy_configuration
      self.attr_lazy_configuration = { 
        :columns => columns
      }

      # prevent barfing if the plugin is reloaded/loaded twice 
      unless self.respond_to? :column_names_for_join_base_without_attr_lazy 
        self.extend AttrLazy::SingletonMethods
        class << self
          alias_method_chain :construct_finder_sql, :attr_lazy
          alias_method_chain :column_names_for_join_base, :attr_lazy
        end    
      end
      
      include AttrLazy::InstanceMethods
      columns.each do |col|
        class_eval("def #{col}; read_lazy_attribute :#{col}; end", __FILE__, __LINE__)
      end
      
    end

    def column_names_for_join_base
      column_names
    end
    
    def column_names_for_join_base_with_attr_lazy
      @column_names_for_join_base ||= columns.collect{|c| 
        c.name unless attr_lazy_configuration[:columns].include?(c.name.to_sym)
      }.compact
    end
  end
  
  module SingletonMethods
    
    def construct_finder_sql_with_attr_lazy(options)
      options = {:select => unlazy_column_list}.merge(options)
      construct_finder_sql_without_attr_lazy(options)
    end
    
    def unlazy_column_list
      @unlazy ||= columns.collect do |c|
        "#{quoted_table_name}.#{connection.quote_column_name(c.name)}" unless attr_lazy_columns.include?(c.name.to_sym)
      end.compact.join ','
    end
    
    def attr_lazy_columns
      attr_lazy_configuration[:columns]
    end
        
  end
  
  module InstanceMethods
  
    def read_lazy_attribute(att)
      @lazy_attribute_values ||= {} 
      if attribute_names.include?(att.to_s)
        read_attribute att
      else
        @lazy_attribute_values[att] ||= self.class.find(id, :select => att)[att]
      end
    end
    
  end
  
end

class ActiveRecord::Associations::ClassMethods::JoinDependency::JoinBase
  def column_names_with_alias
    unless @column_names_with_alias
      @column_names_with_alias = []
      ([active_record.primary_key] + (active_record.column_names_for_join_base - [active_record.primary_key])).each_with_index do |column_name, i|
        @column_names_with_alias << [column_name, "#{ aliased_prefix }_r#{ i }"]
      end
    end
    return @column_names_with_alias
  end
end

ActiveRecord::Base.send :include, AttrLazy



