require 'spec_helper'

describe Object do
  it "should respond to spawn" do
    Object.should respond_to(:spawn)
  end
  
  it "should respond to queue" do
    Object.should respond_to(:queue)
  end
  
  it "should respond to handle_asynch" do
    Object.should respond_to(:handle_asynch)
  end
  
  context "instances" do
    before do
      @tmp = Object.new
    end
    
    it "should respond to spawn" do
      @tmp.should respond_to(:spawn)
    end
    
    it "should respond to queue" do
      @tmp.should respond_to(:queue)
    end
    
    it "should not respond to handle_asynch" do
      @tmp.should_not respond_to(:handle_asynch)
    end
  end
end

describe Runner::Messaging do 
  before do
    @customer = Customer.new
  end
  
  context "when creating a new runner proxy" do
    it "should return a new task" do
      task = Runner::RunnerProxy.new(Runner::PerformableMethod, String.new, {:method => :count})
      task.should eq Runner::Backend::ActiveRecord::Task
      sleep 0.5
    end
  end
  
  context "when calling a method chained on spawn" do
    it "should return a task" do
      @customer.spawn.do_error.class.should eq Runner::Backend::ActiveRecord::Task
      sleep 0.5
    end
  end
  
  context "when I spawn a new tasks which should run now" do
    context "with yield" do
      it "should set task concurrency_method to yield" do
        task = @customer.spawn(:with => :yield).empty_method
        task.concurrency_method.should eq :yield
      end
      
      context "when an error is thrown" do
        it "should update failed_at on raise" do  
          task = @customer.spawn(:with => :yield).do_error
          task.failed_at.should_not eq nil
        end
        
        it "should call error callback on payload" do
          @customer.should_receive :error
          @customer.spawn(:with => :yield).do_error
        end
      end
    end
  end
end