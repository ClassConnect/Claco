module Delayed
  module Plugins
    class Exceptional < Plugin
      module Notify
        def error(job, error)
          i = 0
          dj = YAML.load(job.handler)
          ::Exceptional.context(Hash[*dj.args.map{|a| ["args#{i}", a.to_s]}.flatten])
            .handle(error, "Delayed::Job: #{dj.object}##{dj.method_name.to_s}")
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