class OmniauthCallbacksController < Devise::OmniauthCallbacksController

	def all
		# raise request.env["omniauth.auth"].to_yaml
		teacher = Teacher.from_omniauth(request.env["omniauth.auth"], current_teacher)
		if teacher.save

			# schedule extraction of profile pictures, give priority to twitter
			teacher.avatar_from_omnihash

			redirect_to root_path and return if session["gs"] == "true"
			redirect_to editinfo_path
		else
			redirect_to new_teacher_registration_url
		end
	end

	alias_method :twitter, :all
	alias_method :facebook, :all

end