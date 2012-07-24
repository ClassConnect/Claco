class Message
	include Mongoid::Document

	field :timestamp, :type => Integer
	field :sender, :type => String
	field :body, :type => String
	field :thread, :type => String

end