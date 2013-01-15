class UserMailer < ActionMailer::Base
	include Sprockets::Helpers::RailsHelper
	include Sprockets::Helpers::IsolatedHelper
	layout 'email'
	default from: "claco <support@claco.com>"


	def request_invite(email)
		mail(from: "Eric Simons <support@claco.com>", to: email, subject: "Thanks for requesting an invite to Claco!") do |format|
			format.html {render "request_invite", :layout => false}
		end
	end

	def new_invite(invitation)
		invitation.status["sent"] = true

		invitation.sent_at = Time.now.to_i

		invitation.save

		if invitation.from == "0"
			@link = "http://www.claco.com/join?key=#{invitation.code}&email=#{CGI.escape(invitation.to)}"

			mail(from: "Eric Simons <support@claco.com>", :to => invitation.to, :subject => "Your Claco beta invite is ready :)") do |format|
				format.html {render "system_invite", :layout => false}
			end
		else
			@sender = Teacher.find(invitation.from)

			@link = "http://www.claco.com/join?ref=#{invitation.from}&email=#{CGI.escape(invitation.to)}"

			mail(from: "#{@sender.first_last} via Claco <support@claco.com>", to: invitation.to, subject: "Come collaborate with me on claco") do |format|
				format.html {render "user_invite", :layout => false}
			end
		end
	end

	def send_nag(invitation)
		if invitation.from == "0"
			@link = "http://www.claco.com/join?key=#{invitation.code}&email=#{CGI.escape(invitation.to)}"
		else
			@link = "http://www.claco.com/join?ref=#{invitation.from}&email=#{CGI.escape(invitation.to)}"
		end

		mail(from: "Team Claco <support@claco.com>", :to => invitation.to, :subject => "Beta invite for claco") do |format|
			format.html {render "invite_nag", :layout => false}
		end
	end

	def new_user(user)
		@name = user.first_last

		mail(from: "Eric Simons <support@claco.com>", :to => user.email, :subject => "Re: Welcome to Claco!") do |format|
			format.html {render "welcome", :layout => false}
		end
	end

	def new_sub(subscriber_id, subscribee_id)
		subscriber = Teacher.find(subscriber_id)
		subscribee = Teacher.find(subscribee_id)

		@pre = "Your learning network just got bigger!"
		@limg = teacher_thumb_lg(subscriber)
		@limg_link = 'http://www.claco.com/' + subscriber.username
		@head = '<a href="' + @limg_link + '" style="font-weight:bolder">' + subscriber.first_last + '</a> has subscribed to you'

		@body = "<br />"
		bioarr = subscriber.glance_info
		bioarr.each do |item|
			@body += "#{item[:content]}<br />"
		end

		@button_info = [{linkto: "http://www.claco.com/" + subscriber.username, text: 'View Profile'}]

		mail(from: "#{subscriber.first_last} via Claco <support@claco.com>", to: subscribee.email, subject: PREFIX_EMAIL.sample + " - #{subscriber.first_last} subscribed to you") do |format|
			format.html {render "message_email"}
		end
	end

	def new_msg(message, sender_id, recipient)
		sender = Teacher.find(sender_id)

		@pre = "Whoa - you have a new message!"
		@limg = teacher_thumb_lg(sender)
		@limg_link = 'http://www.claco.com/' + sender.username
		@head = '<a href="' + @limg_link + '" style="font-weight:bolder">' + sender.first_last + '</a>'
		@body = message.body.rstrip
		@button_info = [{linkto: "http://www.claco.com/messages/#{message.thread}", text: 'View Full Message'}]

		mail(from: "#{sender.first_last} via Claco <support@claco.com>", to: recipient.email, subject: "FYI - #{sender.first_last} sent you a message") do |format|
			format.html {render "message_email"}
		end
	end

	def fork_notification(ogbinder, forkedbinder, forker, forkee)
		@pre = forker.first_last + " thinks you rock!"
		@limg = forker.info.avatar.url
		@limg_link = 'http://www.claco.com/' + forker.username
		@head = '<a href="' + @limg_link + '" style="font-weight:bolder">' + forker.first_last + '</a>'
		@body = ' snapped ' + forkedbinder.title + ' to one of their binders!'
		# @button_info = [{linkto: "http://www.claco.com#{named_binder_route(forkedbinder)}", text: 'Check it out!'}]
		@button_info = []

		mail(from: "#{forker.first_last} via Claco <support@claco.com>", to: forkee.email, subject: PREFIX_EMAIL.sample + " - #{forker.first_last} just used one of your resources") do |format|
			format.html {render "message_email"}
		end
	end

	def collab_announce(teacher)

		mail(from: "Team Claco <support@claco.com>", to: teacher.email, subject:"Exciting updates from Team Claco") do
			format.html {render "collab_announce"}
		end

	end

protected
	def named_binder_route(binder, action = "show")
		if binder.class == Binder
			retstr = "/#{binder.handle}/portfolio"

			if binder.parents.length != 1 
				retstr += "/#{CGI.escape(binder.root)}" 
			end

			retstr += "/#{CGI.escape(binder.title)}/#{binder.id}"

			if action != "show" 
				retstr += "/#{action}" 
			end

			return retstr
		elsif binder.class == String 
			return named_binder_route(Binder.find(binder), action)
		else
			return "/500.html"
		end
	end

	def teacher_thumb_lg(teacher)
		#debugger
		ret = Teacher.thumb_lg(teacher).to_s
		if ret.empty?
			# only display the generating image if the current teacher is viewing the thumb
			#if Teacher.thumbscheduled?(teacher,'avatar_thumb_lg') && signed_in? && teacher.id.to_s == current_teacher.id.to_s
				#asset_path("profile/gen-face-170.png")
			#else
				asset_path("profile/face-170.png")
			#end
		else
			ret
		end
	end
end