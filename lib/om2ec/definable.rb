module Definable

  def self.included(base)
    base.extend ClassMethods
    base.instance_eval do
      alias_method :initialize_without_definition, :initialize
      alias_method :add_object_not_definable, :add_object if method_defined? :add_object

      define_method :initialize do |*args|
        initialize_without_definition *args
        @definitions = self.class.definitions(self)
      end
    end
  end

  def add_object obj, internal_call = false
    if @definitions.nil? || @definitions.map{|definition| definition.add(obj)}.any?{|x| !x.nil? }
      actual_object = (obj.is_a?(Array) ? obj[0] : obj)
      object_dependencies << actual_object
      actual_object.dependant_objects << self
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
    #TODO Mirar definición de completo para puntos.
    #TODO completo es o punto afín o objecto definido con parámetros completos.
    @proper_definition
  end

  def completed_by(definition)
    unless @proper_definition
      @proper_definition = definition
      @internal_object = @proper_definition.generate
    end
  end

  module ClassMethods

    def definition(args)
      self.add_definition(Definition.from_args(args))
    end

    def add_definition(definition)
      self.instance_eval do
        @definitions ||= []
        @definitions << definition
      end
    end

    def definitions(obj)
      @definitions ||= []
      @definitions.dup.each {|d| d.for_object(obj)}
    end
  end
end
