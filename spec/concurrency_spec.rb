require 'spec_helper'

describe Runner::Concurrency do
  context "when I spawn a task" do
    before do
      @customer = Customer.new
    end
    
    it "should run a thread when a ConcurrencyThread is used" do
      threader = Runner::Concurrency::ConcurrencyThread.new
      test_variable = nil
      thread = threader.run do
        test_variable = 1
      end
      thread.join
      test_variable.should eq 1
    end
    
    it "should run a fork when a ConcurrencyFork is used" do
      forker = Runner::Concurrency::ConcurrencyFork.new
      forker.run do
        # This part isn't really testable to my knowledge because Process.detach is called on the child right after
        # Which means the process is out of reach.
      end
    end
    
    context "and I yield a method" do
      it "should use ConcurrencyYield" do
        @yielder = Runner::Concurrency::ConcurrencyYield.new
        Runner::Concurrency::ConcurrencyYield.stub!(:new).and_return @yielder
        
        @yielder.should_receive :run
        task = @customer.spawn(:with => :yield).empty_method
      end
    end
    
    context "and I fork a method" do
      it "should use ConcurrencyFork" do
        @forker = Runner::Concurrency::ConcurrencyFork.new
        Runner::Concurrency::ConcurrencyFork.stub!(:new).and_return @forker
        
        @forker.should_receive :run
        task = @customer.spawn(:with => :fork).empty_method
      end
    end
    
    context "and I thread a method" do
      it "should use ConcurrencyThread" do
        @threader = Runner::Concurrency::ConcurrencyThread.new
        Runner::Concurrency::ConcurrencyThread.stub!(:new).and_return @threader
        
        @threader.should_receive :run
        task = @customer.spawn(:with => :thread).empty_method
      end
    end
    
    context "with I specify an invalid concurrency method" do
      it "should use ConcurrencyFork by default" do
        @forker = Runner::Concurrency::ConcurrencyFork.new
        Runner::Concurrency::ConcurrencyFork.stub!(:new).and_return @forker
        
        @forker.should_receive :run
        task = @customer.spawn(:with => :invalid_concurrency_method).empty_method
      end
      
      context "and I config to raise on concurrency handler" do
        it "should raise an exception" do
          Runner.raise_on_concurrency_handler_error = true
          
          Class.send(:include, Runner::Concurrency::Helper)
          handler = Class.new
          handler.instance_eval do
            def test_raise
              proc do
                concurrency(:invalid_concurrency_method) do
                  # Nothing
                end
              end
            end
          end
          handler.test_raise.should raise_exception(Runner::ConcurrencyHandlerError)
        end
      end
    end
  end
end