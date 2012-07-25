class Conversation
	include Mongoid::Document

	field :author, :type => String
	field :members, :type => Array #Will contain author and recipients
	field :subject, :type => String
	field :unread, :type => Hash #{"id" => "count"}

	def unread_messages(id)

		return self.get_messages[(self.get_messages.size - unread[id])..self.get_messages.size]

	end

	def new_message(params, current_teacher)

		message = Message.new(	:timestamp	=> Time.now.to_i,
								:sender		=> current_teacher.id.to_s,
								:body		=> params[:message][:body],
								:thread		=> self.id.to_s,
								:read_by	=> {current_teacher.id.to_s => Time.now.to_i})

		message.save

		unread.each {|id, count| unread[id] += 1 if id != current_teacher.id.to_s}

		self.save

	end

	def get_messages

		return Message.where(:thread => self.id.to_s).sort_by {|message| message.timestamp}

	end

	def last_message

		return get_messages.last

	end

end