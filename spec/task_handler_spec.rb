require "spec_helper"

describe Runner::TaskHandler do
  before do
    @task_handler = Runner::TaskHandler.new
  end
  
  it "should have a backend" do
    Runner::TaskHandler.backend.should_not eq nil
  end
  
  it "should have a serializer" do
    Runner::TaskHandler.serializer.should_not eq nil
  end
  
  it "should be able to guess a backend" do
    Runner::TaskHandler.guess_backend.should_not eq nil
  end
  
  it "should be able to load a serializer" do
    Runner::TaskHandler.load_serializer.should_not eq nil
  end
  
  it "should have a logger" do
    Runner::TaskHandler.logger.should_not eq nil
  end
  
  context "when preloaded with a Task" do
    before do
      @task_handler.task = Runner::Task.new
    end
    
    it "should always run with the task given when started" do
      @task_handler.stub!(:run_with_single_task).and_return true
      @task_handler.should_receive :run_with_single_task
      @task_handler.start
    end
    
    context "when a task is runned" do
      context "and when it fails to do so" do
        it "should be handled properly" do
          @task_handler.should_receive :handle_failed_task
          @task_handler.stub!(:handle_failed_task).and_return(true)
          
          @task = Runner::Task.new
          @task.stub!(:invoke_task) {raise "an error"}
          
          @task_handler.run(@task)
        end
      end
    end
  end
  
  it "should have a default name" do
    @task_handler.name.should_not be nil
  end
  
  context "when name changes" do
    context "with a resolvable hostname" do
      it "to nil it should reset to default" do
        Socket.stub!(:gethostname).and_return "localhost"
        @task_handler.name = nil
        @task_handler.name.should =~ /pid:(.*) host:(.*)/
      end
    end
    
    context "with an error thrown in Socket" do
      it "should reset to default" do
        Socket.stub!(:gethostname) {raise}
        
        @task_handler.name = nil
        @task_handler.name.should =~ /pid:(.*)/
      end
    end
    
    it "to 'my new name' it should not reset to default" do
      @task_handler.name = "my new name"
      @task_handler.name.should eq "my new name"
    end
  end
  
  context "when no specific task is given" do
    it "should handle the default amount of tasks" do
      5.times {Customer.queue.class_method}
      required = Runner::Backend::ActiveRecord::Task.available(5.hours).count - Runner.task_limit
      task_handler = Runner::TaskHandler.new
      task_handler.start
      sleep 2
      Runner::Backend::ActiveRecord::Task.available(5.hours).should have_at_most(required).items
    end
  end
end