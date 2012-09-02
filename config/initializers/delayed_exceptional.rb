if !Exceptional::Config.api_key.nil? && Rails.env == 'production'
  begin
    class Delayed::Worker
      def handle_failed_job_with_exceptional(job, error)
        Exceptional.handle(error, "Delayed::Job #{self.name}")
        handle_failed_job_without_exceptional(job, error)
        Exceptional.context.clear!
      end
      alias_method_chain :handle_failed_job, :exceptional
      Exceptional.logger.info "Exceptional DJ integration enabled"
    end
  rescue => e
    STDERR.puts "Problem starting Exceptional for Delayed-Job. Your app will run as normal."
    Exceptional.logger.error(e.message)
    Exceptional.logger.error(e.backtrace)
  end
end