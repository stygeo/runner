module Runner
  module Backend
    class DeserializationError < StandardError
    end

    module Base
      def self.included(base)
        base.extend ClassMethods
      end
      
      module ClassMethods
        def enqueue(options = {})
          defaults = {
            :run_method => Runner::TaskHandler::spawn_method
          }
          
          options.merge!(defaults)
          options[:run_method] = options[:method] if options[:method]
          options.delete(:method)
          
          if options[:with]
            options[:concurrency_method] = options[:with]
            options.delete(:with)
          end

          self.create(options).tap do |task|
            task.hook(:enqueue)
            task.perform_now if task.should_perform?
          end
        end
      end
      
      # Instance methods
      def payload_object=(object)
        @payload_object = object
        # Serialize object
        self.handler = Runner::TaskHandler.serializer.dump(object)
      end
      
      def payload_object
        @payload_object ||= Runner::TaskHandler.serializer.load(self.handler)
      rescue TypeError, LoadError, NameError => e
        raise DeserializeError, "Task failed to load: #{e.message}. Handler: #{handler.inspect}"
      end
      
      def perform_now
        spawner = TaskSpawner.new(:task => self, :amount_handlers => 1, :with => concurrency_method)
        
        spawner.start_handlers
      end
      
      def should_perform?
        run_method == TaskHandler::spawn_method
      end
      
      # Called by TaskHandler#run which forks this process in the background
      def invoke_task
        begin
          hook :before
          payload_object.perform
          hook :succes
        rescue => e
          hook :error, e
          raise e
        ensure
          hook :after
        end
      end
      
      def hook(name, opts = {})
        if payload_object.respond_to? name
          method = payload_object.method(name)
          # If arity (required arguments) equals zero just call the method, otherwise pass arguments
          method.arity == 0 ? method.call : method.call(self, opts)
        end
      end
      
      protected
      def set_default_run_at
        self.run_at ||= self.class.db_time_now
      end
    end
  end
end