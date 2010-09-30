require 'spec_helper'

describe Runner::Backend::ActiveRecord::Task do
  before do
    @task_handler = Runner::TaskHandler.new
  end
  
  it "should be able to return all available tasks" do
    Customer.queue.class_method
    sleep 0.2
    Runner::Backend::ActiveRecord::Task.find_available_tasks(@task_handler).should have_at_least(1).items
  end
  
  it "should return at least one available task" do
    Customer.queue.class_method
    sleep 0.2
    Runner::Backend::ActiveRecord::Task.available(5.hours).should have_at_least(1).items
  end
end