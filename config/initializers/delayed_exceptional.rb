# if !Exceptional::Config.api_key.nil?# && Rails.env == 'production'
#   begin
#     class Delayed::Worker
#       def handle_failed_job_with_exceptional(job, error)
#         Exceptional.handle(error, "Delayed::Job #{self.name}")
#         handle_failed_job_without_exceptional(job, error)
#         Exceptional.context.clear!
#       end
#       alias_method_chain :handle_failed_job, :exceptional
#       Exceptional.logger.info "Exceptional DJ integration enabled"
#     end
#   rescue => e
#     STDERR.puts "Problem starting Exceptional for Delayed-Job. Your app will run as normal."
#     Exceptional.logger.error(e.message)
#     Exceptional.logger.error(e.backtrace)
#   end
# end
module Delayed
  module Plugins
    class Exceptional < Plugin
      module Notify
        def error(job, error)
          ::Exceptional.handle(error, "BOMB")
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