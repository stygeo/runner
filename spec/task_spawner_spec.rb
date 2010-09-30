require "spec_helper"

describe Runner::TaskSpawner do
  context "when initialized with one task" do
    it "should have one task handler" do
      @task_spawner = Runner::TaskSpawner.new(:task => Runner::Task.new)
      @task_spawner.task_handlers.count.should eq 1
    end
  end
  
  context "initialized without a task" do
    before do
      amount = Array.new
      amount.stub!(:count).and_return(320.0)
      
      Runner::Task.stub!(:available).and_return(amount)
      @requirement = (amount.count / Runner.task_limit.to_f).ceil
    end
    
    it "should have the right amount of task handlers" do
      Runner::TaskSpawner.new.task_handlers.count.should eq @requirement
    end
    
    context "when handling tasks" do
      before do
        @spawner = Runner::TaskSpawner.new
        @spawner.task_handlers.each {|th| th.stub!(:start)}
        @spawner.stub!(:concurrency).and_yield
      end
      
      it "should call before fork" do
        Runner::TaskHandler.backend.stub!(:before_fork)
        Runner::TaskHandler.backend.should_receive(:before_fork).exactly(@requirement).times
        @spawner.start_handlers
      end
      
      it "should call after fork" do
        Runner::TaskHandler.backend.stub!(:after_fork)
        Runner::TaskHandler.backend.should_receive(:after_fork).exactly(@requirement).times
        @spawner.start_handlers
      end
    end
  end
end