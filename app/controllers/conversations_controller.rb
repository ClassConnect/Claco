class ConversationsController < ApplicationController
	before_filter :authenticate_teacher!

	#TODO THIS NEEDS TO BE OPTIMIZED
	def show

		@conversation = Conversation.find(params[:id])

		redirect_to "/messages" and return if !@conversation.members.include?(current_teacher.id.to_s)

		@other = Teacher.find(@conversation.get_other(current_teacher.id.to_s))

		@unread = @conversation.unread_messages(current_teacher.id.to_s)

		@title = "#{@other.full_name} - Messages"

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


		@conversation = Conversation.new(	:members	=> members,
											:unread		=> unread)

		@conversation.save

		@conversation.new_message(params, current_teacher)

		redirect_to conversations_path

	end

	def newmessage


		@conversation = Conversation.find(params[:id])

	end

	def createmessage

		recipient = Teacher.where(:username => /^#{Regexp.escape(params[:username])}$/i).first if params[:id].nil?

		@conversation = Conversation.where(:members => [recipient.id.to_s, current_teacher.id.to_s].sort).first if params[:id].nil?

		@conversation = Conversation.find(params[:id]) if !params[:id].nil?

		if @conversation.nil?
			unread = {current_teacher.id.to_s => 0, recipient.id.to_s => 1}

			@conversation = Conversation.new(	:members => [recipient.id.to_s, current_teacher.id.to_s].sort,
												:unread => unread)

			@conversation.save
		end

		@conversation.new_message(params, current_teacher)

		redirect_to show_conversation_path(@conversation) and return if !params[:id].nil?

		respond_to do |format|
			format.html {render :text => 1}
		end

	end

	# def createmessage

	# 	@conversation = Conversation.find(params[:id])

	# 	@conversation.new_message(params, current_teacher)

	# 	redirect_to show_conversation_path(@conversation)

	# end

end