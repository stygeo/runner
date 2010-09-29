require 'timeout'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/core_ext/kernel'
require 'logger'

module Runner
  class TaskHandler
    attr_accessor :task
    cattr_accessor :spawn_method, :queue_method, :min_priority, :max_priority, :max_run_time, :logger
    self.spawn_method = :spawn
    self.queue_method = :queue
    self.max_run_time = 5.hours
    
    self.logger = if defined?(Rails)
      Rails.logger
    elsif defined?(RAILS_DEFAULT_LOGGER)
      RAILS_DEFAULT_LOGGER
    end
    
    cattr_reader :backend
    def self.backend=(backend)
      if backend.is_a? Symbol
        require "runner/backend/#{backend}"
        backend = "Runner::Backend::#{backend.to_s.classify}::Task".constantize
      end
      
      @@backend = backend
      silence_warnings { ::Runner.const_set(:Task, backend) }
    end
    
    def self.guess_backend
      self.backend ||= :active_record if defined?(ActiveRecord)
    end

    cattr_reader :serializer
    def self.serializer=(serializer)
      if serializer.is_a? Symbol
        require "runner/serialization/#{serializer}"
        serializer = "Runner::Serialization::#{serializer.to_s.classify}::Serializer".constantize
      end
      
      @@serializer = serializer
      silence_warnings { ::Runner.const_set(:Serializer, serializer) }
    end
    
    def self.load_serializer
      self.serializer ||= ::Runner.serializer
    end
    
    # Instance methods
    def initialize(opts = {})
      if opts[:task]
        @task = opts[:task]
      end
    end
    
    # Every worker has a unique name, which is set by default below. 
    # Setting the worker's name has advantages over the default, because it
    # may resume crashed/restart handlers.
    def name
      return @name unless @name.blank?
      "pid:#{Process.pid} host:#{Socket.gethostname}" rescue "pid:#{Process.pid}"
    end
    
    # Set the name of the worker.
    # Setting the name of a worker has advantages. See def name for more details.
    def name=(val)
      @name = val
    end
    
    # Start the worker
    def start
      if @task
        return run_with_single_task
      else
        return result = work_off_tasks
      end
    end
    
    # Work off a single task. Method is used if TaskHandeler was initialized with a task.
    def run_with_single_task
      if lockable?(@task)
        run(@task)
        return true
      end
      
      return false
    end
    
    # Work off the tasks that will be given by lock_and_run
    def work_off_tasks(num = 100)
      stats = {:success => 0, :failure => 0}
      num.times do 
        case lock_and_run_next_available_task
        when true
          stats[:success] += 1
        when false
          stats[:failure] += 1
        else
          break # No work 
        end
      end
      log("Finished working off tasks. Finished with #{stats[:success]} successful and #{stats[:failure]} failed tasks.")
      return stats
    end
    
    # Run 
    def run(task)
      begin
        task.invoke_task
        task.update_attribute(:finished, true)
      rescue => e
        handle_failed_task(task, e)
      end
    end
    
    def lockable?(task, max_run_time = self.class.max_run_time)
      if task.lock!(name, max_run_time)
        return true
      else
        return false
      end
    end
    
    def log(text, level = Logger::INFO)
      text = "[TaskHandler(#{name})] #{text}"
      logger.add level, "#{Time.now.strftime('%FT%T%z')}: #{text}" if logger
    end
    
    protected
    def lock_and_run_next_available_task
      task = Runner::Task.find_available_tasks(name, self.max_run_time).detect do |task|
        lockable?(task)
      end

      run task if task
    end
    
    def handle_failed_task(task, error)
      task.last_error = [error.message, error.backtrace.join("\n")].join("\n")
      task.failed_at = Time.now
      
      log(task.last_error)
      
      task.save # TODO implement reschedule and move task.save to reschedule
      # reschedule(task)
    end
  end
end