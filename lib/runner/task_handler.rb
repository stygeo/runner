module Runner
	class TaskHandler
		cattr_accessor :spawn_method, :queue_method
		self.spawn_method = 0
		self.queue_method = 1
		
		def initialize(task, opts = {})
			@task = task
			
			self.run
		end
		
		def run
			child = fork do 
				begin
					payload_object = @task.payload_object
					payload_object.perform
				rescue => e
					#@task.
				end
			end
			
			Process.detach(child)
		end
	end
end