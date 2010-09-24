require 'active_record'

class ActiveRecord::Base
  yaml_as "tag:ruby.yaml.org,2002:ActiveRecord"

  def self.yaml_new(klass, tag, val)
    klass.find(val['attributes']['id'])
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def to_yaml_properties
    ['@attributes']
  end
end

module Runner
  module Backend
    module ActiveRecord
      class Task < ::ActiveRecord::Base
        include Runner::Backend::Base
        set_table_name :background_tasks

        before_save :set_default_run_at

        scope :flagged_for_run, ->(){
          where(:run_method => Runner::TaskHandler::queue_method, :finished => false)
        }
        scope :by_priority, order('priority ASC, run_at ASC')
        
        scope :ready_to_run, ->(task_handler_name, max_run_time) {
          flagged_for_run.where(['(run_at <= ? AND (locked_at IS NULL OR locked_at < ?) OR locked_by = ?) AND failed_at IS NULL', db_time_now, db_time_now - max_run_time, task_handler_name])
        }
        
        def self.after_fork
          ::ActiveRecord::Base.establish_connection
        end

        # Set limit to 0 for unlimited
        def self.find_available_tasks(task_handler_name, limit = 5, max_run_time = TaskHandler.max_run_time)
          scope = self.ready_to_run(task_handler_name, max_run_time)
          #scope = scope.where(["priority >= ?", TaskHandler.min_priority]) if TaskHandler.min_priority
          #scope = scope.whire(['priority <= ?', TaskHandler.max_priority]) if TaskHandler.max_priority
          
          #::ActiveRecord::Base.silence do
            scope.by_priority.all(:limit => limit) if limit
          #end
        end
        
        def lock!(worker, max_run_time)
          now = self.class.db_time_now
          affected_rows = if locked_by != worker
            # Lock it if it's not locked by us yet
            self.class.update_all(["locked_at = ?, locked_by = ?", now, worker],
                                  ["id = ? AND (locked_at IS NULL OR locked_at < ?) AND (run_at <= ?)", id, (now - max_run_time.to_i), now])
          else
            # Did a worker crash?
            self.class.update_all(["locked_at = ?", now], ["id = ? AND locked_by = ?", id, worker])
          end
        end
        
        # Get the current time (GMT or local depending on DB)
        # Note: This does not ping the DB to get the time, so all your clients
        # must have syncronized clocks.
        def self.db_time_now
          if Time.zone
            Time.zone.now
          elsif ::ActiveRecord::Base.default_timezone == :utc
            Time.now.utc
          else
            Time.now
          end
        end
      end
    end
  end
end