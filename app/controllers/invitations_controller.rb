class InvitationsController < ApplicationController
	before_filter :authenticate_teacher!

	def invite
		render "invite", :layout => false
	end

	def create

		inv = Invitation.new(	:from	=> current_teacher.id.to_s,
								:to		=> params[:to])

		if inv.save

			Invitation.delay(:queue => "email").blast(inv.id)

		else



		end

	end

end