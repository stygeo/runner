module Runner
  class ConcurrencyHandlerError < StandardError
  end
  
  module Concurrency
    module Helper
      def concurrency(method = Runner.default_spawn_method, options = {}, &block)
        # Make sure we can constantize handler.
        # Raise handler error if flag is set
        # else fall back to default fork
        begin
          klass = "Runner::Concurrency::Concurrency#{method.to_s.classify}".constantize
        rescue => e
          raise Runner::ConcurrencyHandlerError "Unable to load class Concurrency#{method.to_s.classify} which was specified as concurrency handler.\n#{e}" if Runner.raise_on_concurrency_handler_error
        ensure
          # Fall back to default fork
          klass = ConcurrencyFork
        end
        
        instance = klass.new(options)
        instance.run(&block)
      end
    end
    
    class ConcurrencyThread
      def run(&block)
        Thread.abort_on_exception = Runner.thread_abort_on_exception
        thread = Thread.new do
          block.call
        end
        thread.run
      end
    end
    
    class ConcurrencyFork
      def run(&block)
        child = fork do
          block.call
        end
        
        Process.detach(child)
      end
    end
    
    class ConcurrencyYield
      def run(&block)
        block.call
      end
    end
  end
end