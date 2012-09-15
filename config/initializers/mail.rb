ActionMailer::Base.register_interceptor(SendGrid::MailInterceptor)

ActionMailer::Base.smtp_settings = {
  :address => 'smtp.sendgrid.net',
  :port => '25',
  :domain => 'claco.com',
  :authentication => :plain,
  :user_name => 'teamclaco',
  :password => 'cc221g7tx'
}