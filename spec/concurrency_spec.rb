describe "concurrency" do
  context "when I spawn a task" do
    before do
      @customer = Customer.new
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
        task = @customer.spawn(:with => :fork).do_error
      end
    end
    
    context "and I thread a method" do
      it "should use ConcurrencyThread" do
        @threader = Runner::Concurrency::ConcurrencyThread.new
        Runner::Concurrency::ConcurrencyThread.stub!(:new).and_return @threader
        
        @threader.should_receive :run
        task = @customer.spawn(:with => :thread).do_error
      end
    end
  end
end