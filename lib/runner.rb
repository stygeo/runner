require 'active_support'

require File.dirname(__FILE__) + '/runner/messaging'
require File.dirname(__FILE__) + '/runner/performable_method'
require File.dirname(__FILE__) + '/runner/yaml_ext'
require File.dirname(__FILE__) + '/runner/backend/base'
require File.dirname(__FILE__) + '/runner/task_spawner'
require File.dirname(__FILE__) + '/runner/task_handler'
require File.dirname(__FILE__) + '/runner/engine' if defined? Rails && Rails::VERSION::MAJOR == 3
	
Object.send(:include, Runner::Messaging)
Module.send(:include, Runner::Messaging::ClassMethods)
