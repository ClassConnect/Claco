class Conversation
	include Mongoid::Document

	field :author, :type => String
	field :members, :type => Array #Will contain author and recipients
	field :subject, :type => String
	#field :messages, :type => Array

	#Gets reset each time a new message is posted... change to message level attribute?
	field :read_by, :type => Array #{:id, :timestamp}

	def read_by?(id)

		self.read_by.each {|x| return true if x["id"] == id.to_s}

		return false

	end

	def add_read(teacher_obj)

		self.read_by << {"id" => teacher_obj.id.to_s, "timestamp" => Time.now.to_i}

		self.save

	end

	def new_message(params, current_teacher)

		message = Message.new(	:timestamp	=> Time.now.to_i,
								:sender		=> current_teacher.id.to_s,
								:body		=> params[:message][:body],
								:thread		=> self.id.to_s)

		message.save

		self.update_attributes(	:read_by => [{	"id" => current_teacher.id.to_s,
												"timestamp" => Time.now.to_i}])

	end

	def get_messages

		return Message.where(:thread => self.id.to_s).sort_by {|message| message.timestamp}

	end

	def last_message

		return get_messages.last

	end

end