require 'spec_helper'

describe Runner::PerformableMethod do
  it "initialize should raise when method_name can't be called" do
    proc { Runner::PerformableMethod.new(Object, :count, nil) }.should raise_exception(NoMethodError)
  end
end