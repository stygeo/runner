require "spec_helper"

describe Runner::TaskHandler do
  before do
    @task_handler = Runner::TaskHandler.new(:task => @task)
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
      it "to nil it should reset to default" do
        Socket.stub!(:gethostname) do
          raise
        end
        
        @task_handler.name = nil
        @task_handler.name.should =~ /pid:(.*)/
      end
    end
    
    it "to 'my new name' it should not reset to default" do
      @task_handler.name = "my new name"
      @task_handler.name.should eq "my new name"
    end
  end
end