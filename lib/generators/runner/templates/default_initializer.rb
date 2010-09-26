# Runner's default initializer. See documentation for available options
Runner.setup do |config|
  ## Set the default concurrency handler. By default all child tasks get forked.
  # config.default_spawn_method = :fork
  
  ## Throw an exception if an undefined concurrency handler is specified. Default is false
  # config.raise_on_concurrency_handler_error = false
  
  ## Abort all threads if one a thread raises an error. Default is false
  # config.thread_abort_on_exception = false
  
  ## Amount of task a task handler will process. Default is false
  # config.task_limit
end