module Delayed
  module Plugins
    class Exceptional < Plugin
      module Notify
        def error(job, error)
          ::Exceptional.handle(error, "Delayed::Job: #{job.handler}")
          super
        end
      end

      callbacks do |lifecycle|
        lifecycle.before(:invoke_job) do |job|
          payload = job.payload_object
          payload = payload.object if payload.is_a? Delayed::PerformableMethod
          payload.extend Notify
        end
      end
    end
  end
end

Delayed::Worker.plugins << Delayed::Plugins::Exceptional