require 'active_support/core_ext/class/attribute_accessors'
require 'active_record'

module Runner
  class TaskSpawner
    attr_accessor :with
    include Runner::Concurrency::Helper
    
    cattr_accessor :max_amount_task_handlers
    self.max_amount_task_handlers = 5
    
    def initialize(options = {})
      @task_handlers = Array.new
      
      if options[:task].blank?
        options.reverse_merge!({:amount_handlers => TaskSpawner::max_amount_task_handlers})
          
        # Determine the amount of handlers required
        amount_needed = (Task.available(TaskHandler.max_run_time).count.to_f / Runner.task_limit.to_f).ceil
        amount_needed.times do 
          @task_handlers << TaskHandler.new
        end
      else
        @task_handlers << TaskHandler.new(:task => options[:task])
      end
      
      @with = options[:with] || Runner.default_spawn_method
    end
    
    def start_handlers
      @task_handlers.each do |task_handler|
        TaskHandler.backend.before_fork
        
        concurrency(@with) do
          # Restore connection for this fork
          TaskHandler.backend.after_fork
            
          task_handler.start
        end
      end
    end
  end
end