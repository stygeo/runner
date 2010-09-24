require 'timeout'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/core_ext/kernel'
require 'logger'

module Runner
	class TaskHandler
		cattr_accessor :spawn_method, :queue_method, :min_priority, :max_priority, :max_run_time
		self.spawn_method = 0
		self.queue_method = 1
		self.max_run_time = 5.hours
		
		def initialize(opts = {})
			# TODO
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
		
		# Run 
		def run(task)
			child = fork do 
				begin
					@talk.invoke_task
				rescue => e
					handle_failed_task(task, e)
				end
			end
			
			Process.detach(child)
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
		
		protected
		def lock_and_run_next_available_job
			task = Runner::Task.find_available_tasks(name, self.max_run_time).detect do |task|
				return lockable?(name, task)
			end
			
			run task if task
		end
		
		def handle_failed_task(task, error)
			task.last_error = [error.message, error.backtrace.join("\n")].join("\n")
			# reschedule(task)
		end
	end
end