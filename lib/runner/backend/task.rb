require 'active_record'

module Runner
	module Backend
		module ActiveRecord
			class Task < ::ActiveRecord::Base
				include Runner::Backend::Base
				
				scope :flagged_for_run, ->(){
					where(:run_method => Runner::TaskHandler::queue_method, :done_running => false)
				}
				
				def self.after_fork
					::ActiveRecord::Base.establish_connection
				end
			end
		end
	end
end