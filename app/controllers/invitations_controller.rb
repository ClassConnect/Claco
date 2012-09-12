class InvitationsController < ApplicationController
	before_filter :authenticate_teacher!

	def invite
		@invitations = Invitation.where(:from => current_teacher.id.to_s).sort_by{|i| i.submitted}

		render "invite", :layout => false
	end

	def create

		emails = params[:invite]

		emails.each do |email|

			inv = Invitation.new(	:from	=> current_teacher.id.to_s,
									:to		=> email)

			if inv.save

				Invitation.delay(:queue => "email").blast(inv.id.to_s)

			else



			end

		end

		redirect_to root_path

	end

end