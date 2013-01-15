namespace :email do

	task :collab_announce do

		Teacher.all.each do |teacher|

			UserMailer.collab_announce(teacher).deliver

		end

	end

end