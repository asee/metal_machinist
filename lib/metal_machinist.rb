module MetalMachinist
  module Lathe  
    
    # Altered to expect blueprints in an array.  Blueprints come in a load order, 
    # and we expect the last defined blueprint to be the most authoritative.  This applies
    # if it is defined twice in one file or overridden in another file.
    #A
    def run_with_array_support(adapter, object, *args)
      blueprints       = object.class.blueprints
      named_blueprints = object.class.blueprints(args.shift) if args.first.is_a?(Symbol)
      attributes       = args.pop || {}
      
      # The first blueprint to run is the most recently defined named blueprint.
      # The last blueprint to run is the first defined unnamed blueprint.
      # This is important because once an attribute or relation is set it will not be overwritten
      ordered_blueprints = Array(named_blueprints).reverse + Array(blueprints).reverse
      raise "No blueprint for class #{object.class}" if ordered_blueprints.blank?
      
      returning self.new(adapter, object, attributes) do |lathe|
        ordered_blueprints.each {|blueprint| lathe.instance_eval(&blueprint)}
      end
    end
    
    # For comparison, the original machinist run method:
    # def self.run(adapter, object, *args)
    #   blueprint       = object.class.blueprint
    #   named_blueprint = object.class.blueprint(args.shift) if args.first.is_a?(Symbol)
    #   attributes      = args.pop || {}
    #   raise "No blueprint for class #{object.class}" if blueprint.nil?
    #   returning self.new(adapter, object, attributes) do |lathe|
    #     lathe.instance_eval(&named_blueprint) if named_blueprint
    #     lathe.instance_eval(&blueprint)
    #   end
    # end
  end
  
  # Altered to check for a block and allow redefinitions.
  #
  module LatheInstance
    def method_missing_with_array_support(symbol, *args, &block)
      if attribute_assigned?(symbol)
        # If we've already assigned the attribute, return that.
        @object.send(symbol)
      elsif @adapter.has_association?(@object, symbol) && !@object.send(symbol).nil?
        # If the attribute is an association and is already assigned, return that.
        @object.send(symbol)
      else
        # Otherwise generate a value and assign it.
        assign_attribute(symbol, generate_attribute_value(symbol, *args, &block))
      end
    end
    
    # The original method missing:
    # def method_missing(symbol, *args, &block)
    #   if attribute_assigned?(symbol)
    #     # If we've already assigned the attribute, return that.
    #     @object.send(symbol)
    #   elsif @adapter.has_association?(@object, symbol) && !@object.send(symbol).nil?
    #     # If the attribute is an association and is already assigned, return that.
    #     @object.send(symbol)
    #   else
    #     # Otherwise generate a value and assign it.
    #     assign_attribute(symbol, generate_attribute_value(symbol, *args, &block))
    #   end
    # end
  end
  
  # Altered to store blueprints in an array
  #
  module Blueprints
    def blueprint_with_array_support(name = :master, &blueprint)
      @blueprints ||= {}
      @blueprints[name] ||= []
      @blueprints[name] << blueprint if block_given?
      @blueprints[name]
    end  
    
    # The original blueprint method:
    # def blueprint(name = :master, &blueprint)
    #   @blueprints ||= {}
    #   @blueprints[name] = blueprint if block_given?
    #   @blueprints[name]
    # end
  end
end

Machinist::Lathe.class_eval do
  extend MetalMachinist::Lathe
  class << self  
    alias_method_chain :run, :array_support
  end
  include MetalMachinist::LatheInstance
  alias_method_chain :method_missing, :array_support
end

ActiveRecord::Base.class_eval do
  extend MetalMachinist::Blueprints
  class << self  
    alias_method_chain :blueprint, :array_support
    alias :blueprints :blueprint
  end
end
