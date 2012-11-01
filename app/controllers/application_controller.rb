class ApplicationController < ActionController::Base
  prepend_before_filter :store_location
  # protect_from_forgery


  protected
    def store_location
      session[:teacher_return_to] ||= ""
      session[:teacher_return_to] = request.fullpath if session[:teacher_return_to].include?(request.fullpath) && request.fullpath != destroy_teacher_session_path && !request.fullpath.include?("favicon.ico") && request.fullpath != new_teacher_session_path
    end

    # def after_sign_in_path_for(resource)
    #   return root_path if session[:teacher_return_to].nil? || session[:teacher_return_to].last == request.fullpath
    #   session[:teacher_return_to].last || root_path
    # end

    def authenticate_admin!
      render "errors/not_found", :status => 404 unless signed_in? && current_teacher.admin
    end

  	def after_sign_out_path_for(resource_or_scope)
    	root_path
  	end
end