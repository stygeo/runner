require 'spec_helper'

describe Runner::PerformableMethod do
  it "initialize should raise when method_name can't be called" do
    proc { Runner::PerformableMethod.new(Object, :count, nil) }.should raise_exception(NoMethodError)
  end
  
  context "with a proper object" do
    before do
      @performable = Runner::PerformableMethod.new(Array.new, :count, nil)
    end
    
    it "should have a display_name" do
      @performable.display_name.should eq "Array#count"
    end
  end
end