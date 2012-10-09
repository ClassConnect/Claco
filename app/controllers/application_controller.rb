class ApplicationController < ActionController::Base
  before_filter :store_location
  # protect_from_forgery

  #include Oink::MemoryUsageLogger
  #include Oink::InstanceTypeCounter



  protected
    def store_location
      session[:previous_urls] ||= []
      # store unique urls only
      session[:previous_urls].prepend request.fullpath if session[:previous_urls].first != request.fullpath && request.fullpath != destroy_teacher_session_path && !request.fullpath.include?("favicon.ico") && request.fullpath != new_teacher_session_path
      # For Rails < 3.2
      # session[:previous_urls].unshift request.fullpath if session[:previous_urls].first != request.fullpath 
      session[:previous_urls].pop if session[:previous_urls].count > 2
    end

    def after_sign_in_path_for(resource)
      session[:previous_urls].last || root_path
    end

    def authenticate_admin!
      render "public/404.html", :status => 404 unless signed_in? && current_teacher.admin
    end

  	def after_sign_out_path_for(resource_or_scope)
    	root_path
  	end
end