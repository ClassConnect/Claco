class ApplicationController < ActionController::Base
  # protect_from_forgery

	#include Oink::MemoryUsageLogger
	#include Oink::InstanceTypeCounter

  protected
  def authenticate_admin!
    render "public/404.html", :status => 404 unless signed_in? && current_teacher.admin
  end

	def after_sign_in_path_for(resource_or_scope)
		root_path
	end

	def after_sign_out_path_for(resource_or_scope)
  	root_path
	end
end
