require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Definable do
  before(:each) do
    @class = Class.new do
      include Definable
      attr_accessor :assertion
      definition [Point, Point] => Midpoint
      definition [Point, [Line, :parallel]] => ParallelLine
      definition [Point, [Line, :perpendicular]] => PerpendicularLine
    end
    @definable = @class.new
    [@class, @definable].each do |var|
      def var.definitions
        self.instance_variable_get("@definitions")
      end
    end
  end

  after(:each) do
    Midpoint.expected_arguments.should_not be_empty
    ParallelLine.expected_arguments.should_not be_empty
  end

  context "when including Definable" do
    it "should extend Definable::ClassMethods" do
      @class.should extend(Definable::ClassMethods)
    end

    it "should force the target to include Constructable" do
      Midpoint.should include(Definable::Constructable)
    end 

    context "with definitions" do
      subject{@definable.definitions}

      specify{ should_not be_nil}
      specify{ should_not be_equal(@class.definitions)} 
    end
  end

  context "when adding an object" do
    
    it "should call add in all definitions" do
      point = Point.new
      @definable.definitions.each{|d| d.should_receive(:add).with(point)}
      @definable.add_object point
    end

    context "completing a definition" do

      it "should call completed_by" do
        @definable.should_receive(:completed_by).with(@definable.definitions[0])
        @definable.add_object Point.new
        @definable.add_object Class.new(Point).new
      end
    end

    context "when object is actually added" do

      before(:each) do
        @p = Point.new
        @definable.add_object @p
      end
      
      it "should add added object to dependencies" do
        @definable.object_dependencies.should include(@p)
      end

      it "should add itself to dependant objects" do
        @p.dependant_objects.should include(@definable)
      end
    end

    context "when object is not actually added" do

      before(:each) do
        @o = Class.new.new
        @definable.add_object @o
      end
      
      it "should not add added object to dependencies" do
        @definable.object_dependencies.should_not include(@o)
      end

      it "should not be in the object dependant_objects" do
        lambda{
          @o.dependant_objects.should_not include(@definable)
        }.should raise_error
      end

      context "when added object responds to add_object" do
        it "should call add_object in the parameter" do
          @definable.should_receive(:add_object).once.with(@definable)
          @definable.add_object @definable
        end
      end

      context "when added object does not responds to add_object" do
        it "should not call add_object in the parameter" do
          p = Class.new.new
          p.should_receive(:respond_to?).with(:add_object).and_return(false)
          p.should_not_receive(:add_object)
          @definable.add_object p
        end
      end
    end

    context "when a definition is complete" do

      before(:each) do
        @definable.add_object Class.new(Point).new
        @definable.add_object Class.new(Point).new
        def @definable.internal_object
          @internal_object
        end
      end
      
      it "should get an internal object" do
        @definable.internal_object.should_not be_nil
      end

      it "should get an internal object of the proper class" do
        @definable.internal_object.should be_a(Midpoint)
      end
    end
  end

  context "when adding a hook" do

    describe "#after_creating" do

      subject{ @class }

      it { should respond_to(:after_creating) }

      it "should receive a block" do
        lambda{
          @class.after_creating{|x| "just a block"}
        }.should_not raise_error
      end

      it "should add a block to after_creating_hooks" do
        lambda{
          @class.after_creating{|x| "just a block"}
        }.should change{@class.after_creating_hooks.size}.by(1)
      end

      it "should execute all the blocks after creating the object" do
        @class.after_creating do |master, slave|
          master.assertion = true
        end
        @definable.add_object Point.new
        @definable.add_object Point.new
        @definable.assertion.should == true
      end

      it "should call the blocks with the metaobject and the new object" do
        @class.after_creating do |master, slave|
          master.should be_equal(@definable)
          slave.should be_equal(master.instance_variable_get(:@internal_object))
        end
        @definable.add_object Point.new
        @definable.add_object Point.new
      end
    end

    describe "#before_creating" do

      subject{ @class }

      it { should respond_to(:before_creating) }

      it "should receive a block" do
        lambda{
          @class.before_creating{|x| "just a block"}
        }.should_not raise_error
      end

      it "should add a block to after_creating_hooks" do
        lambda{
          @class.before_creating{|x| "just a block"}
        }.should change{@class.before_creating_hooks.size}.by(1)
      end

      it "should execute all the blocks after creating the object" do
        @class.before_creating do |master, slave|
          master.assertion = true
        end
        @definable.add_object Point.new
        @definable.add_object Point.new
        @definable.assertion.should == true
      end

      it "should call the blocks with the metaobject and the new object" do
        @class.before_creating do |master, slave|
          master.should be_equal(@definable)
          slave.should be_a(Definable::Definition)
        end
        @definable.add_object Point.new
        @definable.add_object Point.new
      end
    end
  end
end
