require 'spec_helper'
require 'universa/lazy'

class T1
  @@counter = 0

  extend Universa::Lazy
  include Universa::Lazy

  lazy(:foo) {
    val = @@counter
    @@counter += 1
    sleep(0.01)
    # puts "foo1 #{@counter}"
    val
  }

  lazy(:bar) {
    @data + "!"
  }

  attr :data

  def self.counter
    @@counter
  end

  def initialize
    @data = "buzz"
  end

end

describe LazyValue do

  it "computes once and synchronously" do
    t = T1.new
    values = []
    tt = 1000.times.map {
      Thread.start {
        values << t.foo
      }
    }
    tt.each(&:join)
    T1.counter.should == 1
    values.all?{|x| x == 0}.should be_truthy
  end

  it "access instance vars" do
    t = T1.new
    t.bar.should == "buzz!"
  end
end