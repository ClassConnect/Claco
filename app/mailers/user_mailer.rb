class UserMailer < ActionMailer::Base
	include Sprockets::Helpers::RailsHelper
	include Sprockets::Helpers::IsolatedHelper
	layout 'email'
	default from: "claco <support@claco.com>"

	def request_invite(email)
		mail(from: "Eric Simons <support@claco.com>", to: email, subject: "Thanks for signing up for Claco!") do |format|
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

			mail(from: "#{@sender.first_last} via Claco <support@claco.com>", to: invitation.to, subject: "Beta invite for claco") do |format|
				format.html {render "user_invite", :layout => false}
			end
		end
	end

	def new_user(user)
		@username = user.first_last

		mail(from: "Eric Simons <support@claco.com>", :to => user.email, :subject => "Your Claco account has been created!") do |format|
			format.html {render "welcome"}
		end
	end

	def new_sub(subscriber, subscribee)
		@subscriber = Teacher.find(subscriber)
		@subscribee = Teacher.find(subscribee)

		@pre = "Your learning network just got bigger!"
		@head = '<a href="http://www.claco.com/' + @subscriber.username + '" style="font-weight:bolder">' + @subscriber.first_last + '</a> has subscribed to you'
		# @limg = @subscriber.info.avatar.url
		@limg = teacher_thumb_lg(@subscriber)

		bioarr = @subscriber.glance_info

		@body = "<br />"

		@html_safe = true

		bioarr.each do |item|

			@body += "#{item[:content]}<br />"

		end

		@button_info = [{linkto: "http://www.claco.com/" + @subscriber.username, text: 'View Profile'}]

		mail(from: "#{@subscriber.first_last} via Claco <support@claco.com>", to: @subscribee.email, subject: "FYI - #{@subscriber.first_last} subscribed to you") do |format|
			format.html {render "message_email"}
		end
	end

	def new_msg(message, sender, recipient)
		@message = message
		@sender = Teacher.find(sender)
		@recipient = recipient

		@pre = "Woah - you have a new message!"
		@head = '<a href="http://www.claco.com/' + @sender.username + '" style="font-weight:bolder">' + @sender.first_last + '</a>'
		@button_info = [{linkto: 'http://www.claco.com/messages/' + @message.thread, text: 'View Full Message'}]
		@linkto = 
		@limg = teacher_thumb_lg(@sender)
		@body = @message.body.rstrip

		@html_safe = false

		while @body.last == "."
			@body.chomp!(".")
		end

		mail(from: "#{@sender.first_last} via Claco <support@claco.com>", to: @recipient.email, subject: "FYI - #{@sender.first_last} sent you a message") do |format|
			format.html {render "message_email"}
		end
	end

	def fork_notification(ogbinder, forkedbinder, forker, forkee)
		#All params are actual objects
		@pre = "Nice! " + forker.first_last + "is using your stuff!"
		@head = '<a href="http://www.claco.com/' + forker.username + '" style="font-weight:bolder">' + forker.first_last + '</a>'
		@limg = forker.info.avatar.url
		@resource = forkedbinder
		@linkto = "http://www.claco.com#{named_binder_route(@resource)}"

		# @html_safe = true

		mail(from: "#{forker.first_last} via Claco <support@claco.com>", to: forkee.email, subject: "FYI - #{forker.first_last} just snapped #{@resource.title}!") do |format|
				format.html {render "fork_email"}
		end
	end

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