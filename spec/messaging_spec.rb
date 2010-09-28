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
  
  context "instances of object" do
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
    end
  end
  
  context "when calling a method chained on spawn" do
    it "should return a task" do
      @customer.spawn.error.class.should eq Runner::Backend::ActiveRecord::Task
    end
  end
  
  context "when I spawn a new tasks which should run imediatly" do
    context "when an error is thrown"  do
      it "should updated failed_at attribute and update last_error" do
        task = @customer.spawn.error
        sleep 0.5
        task.failed_at.should_not be nil
      end
    end
  end
  
  context "when I spawn a new tasks which should be queued" do
    context "when an error is thrown" do
      it "should update failed_at" do
        task = @customer.queue.error
        sleep 0.5
        task.failed_at.should_not be nil
      end
    end
  end
end