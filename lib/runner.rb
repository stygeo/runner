require 'active_support'

module Runner
	require 'runner/messaging'
	require 'runner/performable_method'
	require 'runner/engine' if defined? Rails && Rails::VERSION::MAJOR == 3
	require 'runner/backend/base'
	require 'runner/backend/task'
	require 'runner/task_handler'
	
	Object.send(:include, Runner::Messaging)
	Module.send(:include, Runner::Messaging::ClassMethods)
end