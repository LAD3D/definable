# -*- coding: utf-8 -*-
module Definable

  def self.included(base)
    base.extend ClassMethods
    base.instance_eval do
      alias_method :initialize_without_definition, :initialize
      alias_method :add_object_not_definable, :add_object if method_defined? :add_object

      define_method :initialize do |*args|
        # Somehow, this started raising a SystemStackError
        unless @already_initialized
          @already_initialized = true
          initialize_without_definition *args
        end
        @definitions = self.class.definitions(self)
      end
    end
  end

  def add_object obj, internal_call = false
    gd = @definitions.find_all{|d| d.accept?(obj)}
    if !gd.empty?
      gd.map{|d| d.dup(true)}.each do |nd|
        @definitions << nd
        nd.add obj
      end
      actual_object = (obj.is_a?(Array) ? obj[0] : obj)
      object_dependencies << actual_object
      actual_object.dependant_objects << self if actual_object.respond_to? :dependant_objects
    elsif !internal_call
      obj.add_object(self, true) if obj.respond_to?(:add_object)
    end
    self
  end

  def object_dependencies
    @object_dependencies ||= []
  end

  def dependant_objects
    @dependant_object ||= []
  end

  def complete?
    @proper_definition
  end

  def completed_by(definition)
    unless @proper_definition
      @proper_definition = definition
      call_before_creating_hooks(self, @proper_definition)
      @internal_object = @proper_definition.generate
      call_after_creating_hooks(self, @internal_object)
      dependant_objects.each &:complete_ping
      @internal_object
    end
  end

  def complete_ping
    @definitions.each &:check_completeness
  end
  
  protected
  def call_after_creating_hooks(master, slave)
    self.class.after_creating_hooks.each do |b|
      b.call(master,slave)
    end
  end
  
  def call_before_creating_hooks(master, definition)
    self.class.before_creating_hooks.each do |b|
      b.call(master,definition)
    end
  end
  
  module ClassMethods

    def definition(args)
      self.add_definition(::Definable::Definition.from_args(args))
    end

    def add_definition(definition)
      self.instance_eval do
        @definitions ||= []
        @definitions << definition
      end
    end

    def definitions(obj)
      @definitions ||= []
      res = []
      @definitions.each{|x| res << x.dup.for_object(obj)}
      res
    end

    def add_internal_method(*args)
      args.each do |m|
        old_method = instance_method(m)
        self.send(:define_method, m) do |*args|
          int_obj = self.send(:instance_variable_get, :@internal_object)
          if int_obj
            int_obj.send(m, *args)
          else
            old_method.bind(self).call(*args)
          end
        end
      end     
    end

    def after_creating(&block)
      after_creating_hooks << block
    end

    def before_creating(&block)
      before_creating_hooks << block
    end

    def after_creating_hooks
      @after_creating_hooks ||= []
    end

    def before_creating_hooks
      @before_creating_hooks ||= []
    end
  end
end

# Setting up.

$: << File.dirname(__FILE__)
require 'definable/helpers/array.rb'

module Definable

  #autoloads
  autoload :Constructable, File.join(File.dirname(__FILE__), 'definable', 'constructable.rb')
  autoload :Definition, File.join(File.dirname(__FILE__), 'definable', 'definition.rb')
end
