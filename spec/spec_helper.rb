$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'definable'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
  
end

Spec::Matchers.define :contain do |value|
  match do |container|
    container.respond_to?(:contains?) && container.contains?(value)
  end

  failure_message_for_should do |container|
    "expected #{container} to contain value #{value}"
  end

  failure_message_for_should_not do |container|
    "expected #{container} not to contain value #{value}"
  end

  description do
    "expect a container of #{value}"
  end
end

Spec::Matchers.define :extend do |value|
  match do |container|
    container.extend?(value)
  end

  failure_message_for_should do |container|
    "expected #{container} to extend #{value}"
  end

  failure_message_for_should_not do |container|
    "expected #{container} not to extend #{value}"
  end

  description do
    "expect a class extending #{value}"
  end
end

class Object
  def vector?
    self.is_a?(Array) && self.size == 3
  end

  def extend?(mod)
    (class << self; self; end).include? mod
  end
end

class String
  def upcased?
    self == upcase
  end

  def downcased?
    self == downcase
  end
end

module Definable
  class Definition
    def owner
      @owner
    end
  end
end

class Point
  include Definable
  def initialize(*args);@complete=false;end
  def complete?; @complete; end
  def complete; @complete=true; self; end
end
class Midpoint < Point
  def initialize(*args);end
end
class Line
  include Definable
  def initialize(*args);end
end
class ParallelLine<Line
  def initialize(*args);end
end
class PerpendicularLine<Line
  def initialize(*args);end
end
