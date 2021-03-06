class CreateRunnerTasks < ActiveRecord::Migration
  def self.up
    create_table :background_tasks, :force => true do |table|
      table.integer   :priority, :default => 0        # Allows some jobs to jump to the front of the queue
      table.integer   :attempts, :default => 0        # Provides for retries, but still fail eventually.
      table.boolean   :finished, :default => false    # Displays whether the tasks is done or not
      table.text      :run_method                     # The method in when this task should run. Imidiatly or delayed
      table.text      :handler                        # YAML-encoded string of the object that will do work
      table.text      :last_error                     # reason for last failure (See Note below)
      table.text      :concurrency_method             # If a concurrency method is given (yield, thread or fork) save it so we can use it when the object method is invoked
      table.datetime  :run_at                         # When to run. Could be Time.zone.now for immediately, or sometime in the future.
      table.datetime  :locked_at                      # Set when a client is working on this object
      table.datetime  :failed_at                      # Set when all retries have failed (actually, by default, the record is deleted instead)
      table.string    :locked_by                      # Who is working on this object (if locked)
      table.timestamps
    end
  
    add_index :background_tasks, [:priority, :run_at], :name => 'runner_tasks_priority'
  end
  
  def self.down
    drop_table :background_tasks  
  end
end