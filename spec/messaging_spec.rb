require 'spec_helper'

describe Runner::Messaging do 
  before do
    @customer = Customer.new
  end
  
  it "should be true" do 
    true.should == true
  end
  
  context "when an error is thrown"  do
    it "should updated failed_at attribute and update last_error" do
      @customer.spawn.error
      sleep 0.1
      Task.first.failed_at should_not eq(nil) 
    end
  end
end