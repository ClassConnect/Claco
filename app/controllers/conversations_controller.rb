class ConversationsController < ApplicationController
	before_filter :authenticate_teacher!

	def show

		@conversation = Conversation.find(params[:id])

		@unread = @conversation.unread_messages(current_teacher.id.to_s)

		@conversation.unread[current_teacher.id.to_s] = 0

		@conversation.save

		@messages = @conversation.get_messages

		@messages.each do |message|

			message.add_read(current_teacher) if !message.read_by?(current_teacher.id.to_s)

		end

	end

	def new

		@conversation = Conversation.new

	end

	def create

		members = params[:conversation][:members].split.uniq << current_teacher.id.to_s

		unread = {}

		members.each {|member| unread[member] = (member == current_teacher.id.to_s ? 0 : 1)}


		@conversation = Conversation.new(	:author		=> current_teacher.id.to_s,
											:members	=> members,
											:unread		=> unread,
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