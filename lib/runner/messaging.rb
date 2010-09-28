require 'active_support/basic_object'
require 'active_support/core_ext/module/aliasing'

module Runner
  # Proxy class which holds the target so we can, at a later time, perform method calls on it.
  class RunnerProxy < ActiveSupport::BasicObject
    def initialize(payload_class, target, options)
      @payload_class = payload_class
      @target = target
      @options = options
    end
    
    def method_missing(method, *args)
      Task.enqueue({:payload_object => @payload_class.new(@target, method.to_sym, args)}.merge(@options))
    end
  end
  
  module Messaging
    def spawn(options = {}, &block)
      if block_given?
        # Get a unique name
        method_name = "anonymous_runner_method_#{Time.now.to_f}".gsub(".", "")
        
        self.class_eval do
          define_method(method_name) do
            yield
          end
        end
        
        spawn(options).__send__(method_name)
      else
        RunnerProxy.new(PerformableMethod, self, options)
      end
    end
    
    def queue(options = {}, &block)
      options.merge!({:method => :queue})
      spawn(options, &block)
    end

    module ClassMethods
      def handle_asynch(method)
        aliased_method, punctuation = method.to_s.sub(/[?!=]$/, ''), $1
        with_method, without_method = "#{aliased_method}_with_runner#{punctuation}", "#{aliased_method}_without_runner#{punctuation}"
        define_method(with_method) do |*args|
          spawn.__send__(without_method, *args)
        end
        alias_method_chain method, :runner
      end
    end
  end
end
