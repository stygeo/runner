require 'active_support/core_ext/class/attribute_accessors'
require 'active_record'

module Runner
  class TaskSpawner
    attr_accessor :with
    include Runner::Concurrency::Helper
    
    cattr_accessor :max_amount_task_handlers
    self.max_amount_task_handlers = 5
    
    def initialize(options = {})
      options.reverse_merge!({:amount_handlers => TaskSpawner::max_amount_task_handlers})
      @task_handlers = Array.new
      
      options[:amount_handlers].times do 
        @task_handlers << TaskHandler.new
      end
      
      self.with = options[:with] || Runner.default_spawn_method

      @task_handlers.first.task = options[:task] unless options[:task].blank?
    end
    
    def start_handlers
      @task_handlers.each do |task_handler|
        concurrency(self.with) do
          # Restore connection for this fork
          TaskHandler.backend.after_fork
            
          task_handler.start
        end
      end
    end
  end
end