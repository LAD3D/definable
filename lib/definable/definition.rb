module Definable
  
  class Definition

    attr_accessor :result_class
    attr_reader :owner

    alias :result_klazz :result_class
    
    # Arguments are stored in an array of 2-arrays, whose
    # first element is the expected argument, and the second
    # the current argument assigned (nil if none).
    
    def initialize(args, klazz)
      self.result_class = klazz
      self.generic_args= args
      unless klazz.ancestors.include?(Constructable)
        klazz.send :include, Constructable
        klazz.expected_arguments = generic_args
      end
    end
    
    def add(object)
      add_object(object) unless complete?
    end

    # Arguments already passed.
    def arguments
      @arguments.map(&:last).compact
    end

    def complete?
      expected_args.empty? &&
        arguments.map{|x| (x.is_a?(Array)) ? x.first : x}. # Get the actual object
        select{|x| x.respond_to? :complete?}. # Only care about objects that respond to complete?
        all?(&:complete?)
    end

    def dup(args_and_owner_dup=false)
      nd = Definition.new(generic_args.dup, result_klazz)
      if args_and_owner_dup
        arguments.each{|a| nd.add a}
        nd.for_object(owner)
      end
      nd
    end

    # Arguments still not passed
    def expected_args
      @arguments.select{|a| a[1].nil?}.map(&:first)
    end
      
    def for_object(obj)
      @owner = obj
      self
    end

    def generate
      if complete?
        @generated ||= result_klazz.new(*arguments)
      end
    end

    # The whole collection of expected args.
    def generic_args
      @arguments.map &:first
    end
    
    def generic_args=(args)
      @arguments = args.zip([nil]*args.size)
    end
    
    def accept?(object)
      expected_args.any?{|arg| coerceable?(object,arg)}
    end

    class << self

      def from_args(arguments)
        args = parse_args(arguments)
        target = arguments[args]
        target.send :include, Constructable
        target.expected_arguments = args.dup
        self.new(args,target)
      end

      protected

      def can_be_an_arg?(arg)
        self.can_be_a_simple_arg?(arg) || self.can_be_a_tagged_arg?(arg)
      end

      def can_be_a_simple_arg?(arg)
        arg.is_a?(Class)
      end

      def can_be_a_tagged_arg?(arg)
        arg.is_a?(Array) && arg[0].is_a?(Class) && arg[1].is_a?(Symbol)
      end

      def parse_args(arguments)
        arguments.keys.detect{|x| x.is_a?(Array) && x.all?{|y| can_be_an_arg?(y)}}
      end
    end

    private

    # Adds the arg to the first feasible position.
    def add_arg(obj)
      idx = @arguments.index do |generic, actual|
        actual.nil? && coerceable?(obj, generic)
      end
      @arguments[idx][1]=obj
    end  
    
    def add_object(object)
      if expected_args.any? {|x| coerceable?(object,x)}
        add_arg(object)
        owner.completed_by(self) if complete?
        get_actual_object(object)
      end
    end

    def coerceable?(object, arg)
      (arg.is_a?(Module) && object.is_a?(arg)) ||
        (arg.is_a?(Array) && object.is_a?(Array) && arg[0].is_a?(Module) &&
           object[0].is_a?(arg[0]) && arg[1] == object[1])
    end

    def get_actual_object(object)
      if object.is_a? Array
        object[0]
      else
        object
      end
    end
  end
end
