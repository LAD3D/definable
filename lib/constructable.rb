module Constructable

  def self.included(base)
    base.extend ClassMethods
  end

  def retrieve_arguments(arguments)
    if retrieve_test(arguments)
      args = arguments.dup
      expected_arguments.map{|exp_arg| args.delete_first{|x| arg_match_generic_arg(x, exp_arg)}}.
        map{|x| (x.is_a?(Array) ? x[0] : x)}
    else
      raise ArgumentError, "#{self.class} expects #{expected_arguments.join(', ')}, found #{arguments.map(&:class).join(', ')}"
    end
  end

  def retrieve_test(args)
    expected = expected_arguments.dup
    args.each {|arg| expected.delete_first{|generic| arg_match_generic_arg(arg,generic)}}
    expected.empty? && args.size == expected_arguments.size
  end

  protected
  def expected_arguments
    self.class.expected_arguments
  end

  def arg_match_generic_arg(arg, generic_arg)
    if arg.is_a?(Array)
      arg.size == 2 && arg_match_generic_tagged_arg(arg, generic_arg)
    else
      arg_match_generic_simple_arg(arg, generic_arg)
    end
  end

  def arg_match_generic_tagged_arg(arg, generic_arg)
    generic_arg.is_a?(Array) && generic_arg.size == 2 &&
      arg[0].is_a?(generic_arg[0]) && arg[1] == generic_arg[1]
  end

  def arg_match_generic_simple_arg(arg, generic_arg)
    generic_arg.is_a?(Class) && arg.is_a?(generic_arg)
  end

  module ClassMethods
    def expected_arguments
      @expected_arguments
    end

    def expected_arguments=(args)
      @expected_arguments = args.dup
      @expected_arguments.freeze # DO NOT REMOVE. SOMEHOW IT IS GETTING MODIFIED AND SOME SPECS FAIL. THIS IS THE ONLY SOLUTION I HAVE FOUND
    end
  end
end
