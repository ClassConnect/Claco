ActionMailer::Base.register_interceptor(SendGrid::MailInterceptor)

ActionMailer::Base.smtp_settings = {
  :address => 'smtp.sendgrid.net',
  :port => '25',
  :domain => 'example.com',
  :authentication => :plain,
  :user_name => 'classconnectinc',
  :password => 'cc221g7tx'
}