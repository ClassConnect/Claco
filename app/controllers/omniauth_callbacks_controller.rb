class OmniauthCallbacksController < Devise::OmniauthCallbacksController

	def all
		# raise request.env["omniauth.auth"].to_yaml
		teacher = Teacher.from_omniauth(request.env["omniauth.auth"], current_teacher)
		if teacher.save
			redirect_to editinfo_path
		else
			redirect_to new_teacher_registration_url
		end
	end

	alias_method :twitter, :all
	alias_method :facebook, :all

end