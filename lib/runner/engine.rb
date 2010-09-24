require 'runner'
require 'rails'

module Runner
  class Engine < Rails::Engine
    initializer "runner.guess_backend", :after => :initialize do
      Runner::TaskHandler.guess_backend
    end
    
    rake_tasks do
      # Include rake tasks
    end
  end
end