namespace :email do

	task :collab_announce do

		Teacher.all.each do |teacher|

			UserMailer.send_collab_email(teacher).deliver

		end

	end

end