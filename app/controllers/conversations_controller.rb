class ConversationsController < ApplicationController
	before_filter :authenticate_teacher!

	def show

		@conversation = Conversation.find(params[:id])

		@messages = @conversation.get_messages

		read = @conversation.read_by.collect {|t| t["id"]}

		@conversation.add_read(current_teacher) if !read.include?(current_teacher.id.to_s)

	end

	def new

		@conversation = Conversation.new

	end

	def create

		@conversation = Conversation.new(	:author		=> current_teacher.id.to_s,
											:members	=> params[:conversation][:members].split.uniq << current_teacher.id.to_s,
											:read_by	=> [{	"id" 		=> current_teacher.id.to_s,
																"timestamp"	=> Time.now.to_i}],
											:subject	=> params[:conversation][:subject])

		@conversation.save

		@conversation.new_message(params, current_teacher)

		redirect_to conversations_path

	end

	def newmessage

		@conversation = Conversation.find(params[:id])

	end

	def createmessage

		@conversation = Conversation.find(params[:id])

		@conversation.new_message(params, current_teacher)

		redirect_to show_conversation_path(@conversation)

	end

end