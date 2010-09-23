module Runner
	module Backend
		module Base
			def self.included(base)
				base.extend ClassMethods
			end
			
			module ClassMethods
				def enqueue(*args)
					options = {
						:run_method => Runner::TaskHandler::spawn_method
					}
					
					options.merge!(args)
					options[:run_method] = args[:method] if args[:method]
					
					self.create(options).tap do |task|
						task.hook(:enqueue)
						
						task.perform_now
					end
				end
				
				def perform_now
					TaskHandler.new(self)
				end
				
				def payload_object=(object)
					@payload_object = object
					# Serialize object
					self.handler = object.to_yaml
				end
				
				def payload_object
					@payload_object ||= YAML.load self.handler
				rescue TypeError, LoadError, NameError => e
					raise DeserializeError, "Task failed to load: #{e.message}. Handler: #{handler.inspect}"
				end
				
				def hook(name, opts = {})
					if payload_object.respond_to? name
						method = payload_object.method(name)
						# If arity (required arguments) equals zero just call the method, otherwise pass arguments
						method.arity == 0 ? method.call : method.call(self, opts)
					end
				end
			end
		end
	end
end