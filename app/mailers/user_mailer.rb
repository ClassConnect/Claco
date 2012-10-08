class UserMailer < ActionMailer::Base
	include Sprockets::Helpers::RailsHelper
	include Sprockets::Helpers::IsolatedHelper
	layout 'email'
	default from: "claco <support@claco.com>"

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

	def new_invite(invitation)


		invitation.status["sent"] = true

		invitation.sent_at = Time.now.to_i

		invitation.save

		if invitation.from == "0"

			@link = "http://www.claco.com/join?key=#{invitation.code}&email=#{CGI.escape(invitation.to)}"

			mail(from: "Eric Simons <support@claco.com>", :to => invitation.to, :subject => "Your beta invite is ready :)") do |format|
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

	def fork_notification(ogbinder, forkedbinder, forker, forkee)

		#All params are actual objects
		@pre = "Someone has snapped your content!"
		@head = '<a href="http://www.claco.com/' + forker.username + '" style="font-weight:bolder">' + forker.first_last + '</a>'
		@omission = ''#'<a href="http://www.claco.com/messages/' + @message.thread + '" style="font-weight:bolder">view full message</a>'
		@limg = forker.info.avatar.url
		@body = ""

		@html_safe = false

		# mail(from: "#{forker.first_last} via Claco <support@claco.com>", to: forkee.email, subject: "Someone forked") do |format|
		# 		format.html {render "user_invite"}
		# end

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