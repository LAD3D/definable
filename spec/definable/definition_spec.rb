require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Definable

  describe Definition do
    before(:each) do
      @result_class = Class.new do;def initialize(*args);end;end

      classes = [Class.new, Class.new]
      tags = [:parallel, :normal]
      @ready_params = classes.map(&:new).zip(tags)
      @params = classes.zip(tags)
                      
      @definition = Definable::Definition.new(@params, @result_class)
      @owner =  Class.new do
                  include Definable
                end.new
      @definition.for_object(@owner)
    end

    it "should not accept an expected class as parameter" do
      lambda{
        @definition.add @params[0]
      }.should_not change{@definition.instance_variable_get("@args").size}
    end

    context "when adding an object" do
      
      context "when it gets completed" do
        
        it "should call result class' new method" do
          @result_class.should_receive(:new).once
          add_to_definition @definition, *@ready_params
        end

        it "should be complete after adding a all the expected params" do
          add_to_definition @definition, *@ready_params
          @definition.should be_complete
        end
      end

      it "should call complete? when adding an object" do
        @definition.should_receive(:complete?).at_least(1).and_return(false)
        @definition.add @ready_params[1]
      end

      it "should not call add_object if definition is complete" do
        @definition.should_receive(:complete?).at_least(1).and_return(true)
        @definition.should_not_receive(:add_object)
        @definition.add @ready_params[1]
      end
    end

    context "when complete" do
      it "should generate an object" do
        add_to_definition @definition, *@ready_params
        @definition.generate.should_not be_nil
      end
      
      context "when complete" do

        before(:each) do
          @definition.stub!(:complete?).and_return(true)
        end
        
        it "should not add an object even if it is in the definition" do
          lambda{
            @definition.add @ready_params[0]
          }.should_not change{@definition.instance_variable_get("@args").size}
        end
      end
    end

    context "when incomplete" do
      it "should not generate a class" do
        @definition.generate.should be_nil
      end
      
      context "when adding an object" do

        before(:each) do
          @definition.stub!(:complete?).and_return(false)
        end
        
        it "should add an object if it is in the definition" do
          lambda{
            @definition.add @ready_params[0]
          }.should change{@definition.instance_variable_get("@args").size}.by(1)
        end
        
        it "should call :add_object if it is not complete" do
          @definition.should_receive(:add_object).twice
          add_to_definition @definition, *@ready_params
        end
      end
    end

    describe "#can_be_an_arg?" do
      it "should consider both simple and tagged arguments as arguments" do
        Definition.should_receive(:can_be_a_simple_arg?).and_return(false)
        Definition.should_receive(:can_be_a_tagged_arg?).and_return(true)
        Definition.send :can_be_an_arg?, [@result_class, :tag]
      end

      it "should accept a class" do
        Definition.send(:can_be_an_arg?, @result_class).should == true
        Definition.send(:can_be_an_arg?, Class.new).should == true
      end

      it "should accept a class plus a tag" do
        Definition.send(:can_be_an_arg?, [@result_class, :tag]).should == true
        Definition.send(:can_be_an_arg?, [Class.new, :tag]).should == true
      end
    end

    describe "#dup" do

      before(:each) do
        @dup = @definition.dup(true)
      end
      
      it "should not have a nil owner" do
        @dup.owner.should_not be_nil
      end
      
      it "should have the same owner" do
        @dup.owner.should equal(@definition.owner)
      end
    end

    # Methods
    def add_to_definition(definition, *obj)
      obj.each do |o|
        definition.add o
      end
    end
  end
end
