class Message
	include Mongoid::Document

	field :timestamp, :type => Integer
	field :sender, :type => String
	field :body, :type => String
	field :thread, :type => String
	field :read_by, :type => Hash #{:id, :timestamp}

	def read_by?(id)

		return !(read_by[id] == nil)

	end

	def add_read(teacher_obj)

		read_by[teacher_obj.id.to_s] = Time.now.to_i

		self.save

	end

end