require 'timeout'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/core_ext/kernel'
require 'logger'

module Runner
	class TaskHandler
		cattr_accessor :spawn_method, :queue_method, :min_priority, :max_priority, :max_run_time, :logger
		self.spawn_method = 0
		self.queue_method = 1
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
			return "#{Process.pid}"
		end
		
		# Set the name of the worker.
		# Setting the name of a worker has advantages. See def name for more details.
		def name=(val)
			@name = val
		end
		
		# Start the worker
		def start
			if @task
				return quick_run @task
			else
				return result = work_off_tasks
			end
		end
		
		# Work off the tasks that will be given by lock_and_run
		def work_off_tasks(num = 100)
			success, failure = 0, 0
			run.times do 
				case lock_and_run_next_available_job
				when true
					success += 1
				when false
					failure += 1
				else
					break # No work 
				end
			end
			
			return [success, failure]
		end
		
		# Run 
		def run(task)
			begin
				task.invoke_task
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
		
		def quick_run(task)
			if lockable?(task)
				run(task)
				return true
			end
			
			return false
		end
		
		def log(text, level = Logger::INFO)
			text = "[WorkHandler(#{name})] #{text}"
			puts text
			logger.add level, "#{Time.now.strftime('%FT%T%z')}: #{text}" if logger
		end
		
		protected
		def lock_and_run_next_available_job
			task = Runner::Task.find_available_tasks(name, self.max_run_time).detect do |task|
				return lockable?(name, task)
			end
			
			run task if task
		end
		
		def handle_failed_task(task, error)
			task.last_error = [error.message, error.backtrace.join("\n")].join("\n")
			task.save
			log(task.last_error)
			# reschedule(task)
		end
	end
end