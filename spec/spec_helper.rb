$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rubygems'
require 'bundler/setup'
require 'spec'
require 'logger'

require 'active_record'

require 'runner'

Runner::TaskHandler.logger = Logger.new('/tmp/runner_test.log')
ENV['RAILS_ENV'] = 'test'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
ActiveRecord::Base.logger = Runner::TaskHandler.logger
ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do
  create_table :background_tasks, :force => true do |table|
    table.integer   :priority, :default => 0
    table.integer   :attempts, :default => 0
    table.boolean   :finished, :default => 0
    table.text      :run_method
    table.text      :handler
    table.text      :last_error
    table.text      :concurrency_method
    table.datetime  :run_at
    table.datetime  :locked_at
    table.datetime  :failed_at
    table.string    :locked_by
    table.timestamps
  end

  create_table :customers, :force => true do |table|
    table.string :text
  end
end

# Purely useful for test cases...
class Customer < ActiveRecord::Base
  def error
    raise "I raise an error"
  end
  
  def tell
    text
  end
  
  def say_n_times(n, _)
    tell*n
  end
  
  handle_asynch :say_n_times
end

Runner::TaskHandler.backend = :active_record

# Add this directory so the ActiveSupport autoloading works
ActiveSupport::Dependencies.autoload_paths << File.dirname(__FILE__)
