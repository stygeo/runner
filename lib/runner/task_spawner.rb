require 'active_support/core_ext/class/attribute_accessors'
require 'active_record'

module Runner
	class TaskSpawner
		cattr_accessor :max_amount_task_handlers
		self.max_amount_task_handlers = 5
		
		def self.restore_connection
			::ActiveRecord::Base.establish_connection
		end
		
		def initialize(options = {})
			@task_handlers = options[:task_handlers] || []
			
			@task_handlers << options[:task_handler] if options[:task_handler].present?
		end
		
		def start_handlers
			@task_handlers.each do |task_handler|
				child = fork do
					# Restore connection for this fork
					TaskSpawner.restore_connection
						
					task_handler.start
				end

				Process.detach(child)
			end
		end
	end
end