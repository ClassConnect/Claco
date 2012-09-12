class UserMailer < ActionMailer::Base
	default from: "claco <support@claco.com>"

	def new_sub(subscriber, subscribee)

		@subscriber = Teacher.find(subscriber)
		@subscribee = Teacher.find(subscribee)

		@pre = "Your learning network just got bigger!"
		@head = '<a href="http://www.claco.com/' + @subscriber.username + '" style="font-weight:bolder">' + @subscriber.first_last + '</a> has subscribed to you'
		@omission = ""
		@limg = @subscriber.info.avatar.url

		bioarr = @subscriber.glance_info

		@body = "<br />"

		@html_safe = true

		bioarr.each do |item|

			@body += "#{item[:content]}<br />"

		end

		@body += '<a href="http://www.claco.com/' + @subscriber.username + '" style="font-weight:bolder">view profile</a>'

		mail(:to => @subscribee.email, :subject => "FYI - #{@subscriber.first_last} subscribed to you") do |format|
			format.html {render "message_email"}
		end

	end

	def new_msg(message, sender, recipient)

		@message = message
		@sender = Teacher.find(sender)
		@recipient = recipient

		@pre = "Woah - you have a new message!"
		@head = '<a href="http://www.claco.com/' + @sender.username + '" style="font-weight:bolder">' + @sender.first_last + '</a>'
		@omission = '<a href="http://www.claco.com/messages/' + @message.thread + '" style="font-weight:bolder">view full message</a>'
		@limg = @sender.info.avatar.url
		@body = @message.body.rstrip

		@html_safe = false

		while @body.last == "."
			@body.chomp!(".")
		end

		mail(:to => @recipient.email, :subject => "FYI - #{@sender.first_last} sent you a message") do |format|
			format.html {render "message_email"}
		end

	end

	def new_invite(invitation)

		if invitation.sender == "0"

			@link = "http://www.claco.com/join?key=#{invitation.code}"

			invitation.status["sent"] = true

			invitation.save

			mail(:to => invitation.to, :subject => "Your Claco Invite") do |format|
				format.html {render "system_invite"}
			end
		end

	end

end
