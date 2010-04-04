require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Definable

  describe Definition do
    before(:each) do
      @result_class = Class.new do
                        def initialize(*args)
                        end
                      end

      @params = [Class.new, Class.new]
      @definition = Definable::Definition.new(@params, @result_class, [:parallel, :normal])
      @owner =  Class.new do
                  include Definable
                end.new
      @definition.for_object(@owner)
    end

    it "should add an object if it is in the definition" do
      @definition.stub!(:complete?).and_return(false)
      lambda{
        @definition.add Class.new(@params[1]).new
      }.should change{@definition.instance_variable_get("@args").size}.by(1)
    end

    it "should add an object if it is in the definition" do
      @definition.stub!(:complete?).and_return(false)
      lambda{
        @definition.add Class.new(@params[1]).new
      }.should change{@definition.instance_variable_get("@args").size}.by(1)
    end

    it "should call :add_object if it is not complete" do
      @definition.should_receive(:add_object).twice
      add_to_definition @definition, *@params
    end

    it "should be complete after adding a plane and a point" do
      add_to_definition @definition, *@params
      @definition.should be_complete
    end

    it "should call complete? when adding an object" do
      @definition.should_receive(:complete?).at_least(1).and_return(false)
      @definition.add @params[1].new
    end

    it "should not call add_object if definition is complete" do
      @definition.should_receive(:complete?).at_least(1).and_return(true)
      @definition.should_not_receive(:add_object)
      @definition.add @params[1].new
    end

    it "should call result class' new method when completed" do
      @result_class.should_receive(:new).once
      add_to_definition @definition, *@params
    end

    it "should generate an object" do
      add_to_definition @definition, *@params
      @definition.generate.should_not be_nil
    end

    it "should not generate a class if it is not complete" do
      @definition.generate.should be_nil
    end

    it "should consider both simple and tagged arguments as arguments" do
      Definition.should_receive(:can_be_a_simple_arg?).and_return(false)
      Definition.should_receive(:can_be_a_tagged_arg?).and_return(true)
      Definition.send :can_be_an_arg?, [@result_class, :tag]
    end

    it "should consider a class an arg" do
      Definition.send(:can_be_an_arg?, @result_class).should == true
      Definition.send(:can_be_an_arg?, Class.new).should == true
    end

    it "should consider a class plus a tag an arg" do
      Definition.send(:can_be_an_arg?, [@result_class, :tag]).should == true
      Definition.send(:can_be_an_arg?, [Class.new, :tag]).should == true
    end

    # Methods
    def add_to_definition(definition, *classes)
      classes.each do |klazz|
        definition.add Class.new(klazz).new
      end
    end
  end
end
