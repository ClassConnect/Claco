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

		src = Mongo.log(current_teacher.id.to_s,
						__method__.to_s,
						params[:controller].to_s,
						@conversation.id.to_s,
						params)

		@messages.each do |message|

			message.add_read(current_teacher) if !message.read_by?(current_teacher.id.to_s)

			Mongo.log(	current_teacher.id.to_s,
					__method__.to_s,
					params[:controller].to_s,
					message.id.to_s,
					params,
					{:src => src})

		end

	end

	def new

		@conversation = Conversation.new

		Mongo.log(	current_teacher.id.to_s,
					__method__.to_s,
					params[:controller].to_s,
					@conversation.id.to_s,
					params)

	end

	def create

		members = params[:conversation][:members].split.uniq << current_teacher.id.to_s

		unread = {}

		members.each do |member|

			unread[member] = (member == current_teacher.id.to_s ? 0 : 1)
		end


		@conversation = Conversation.new(	:members	=> members,
											:unread		=> unread)

		Mongo.log(	current_teacher.id.to_s,
					__method__.to_s,
					params[:controller].to_s,
					@conversation.id.to_s,
					params)

		@conversation.save

		@conversation.new_message(params, current_teacher)

		redirect_to conversations_path

	end

	def newmessage


		@conversation = Conversation.find(params[:id])

		Mongo.log(	current_teacher.id.to_s,
					__method__.to_s,
					params[:controller].to_s,
					@conversation.id.to_s,
					params)

	end

	def createmessage

		recipient = Teacher.where(:username => /^#{Regexp.escape(params[:username])}$/i).first if params[:id].nil?

		@conversation = Conversation.where(:members => [recipient.id.to_s, current_teacher.id.to_s].sort).first if params[:id].nil?

		@conversation = Conversation.find(params[:id]) if !params[:id].nil?

		Mongo.log(	current_teacher.id.to_s,
					__method__.to_s,
					params[:controller].to_s,
					@conversation.id.to_s,
					params)

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
	
	###############################################################################################

							#    #  ##### #     #####  ##### #####   #### 
							#    #  #     #     #    # #     #    # #    #
							#    #  #     #     #    # #     #    # # 
							######  ####  #     #####  ####  #####   ####
							#    #  #     #     #      #     #  #        #
							#    #  #     #     #      #     #   #  #    #
							#    #  ##### ##### #      ##### #    #  ####

	###############################################################################################

	module Mongo
		extend self

		def log(ownerid,method,model,modelid,params,data = {})

			log = Log.new( 	:ownerid => ownerid.to_s,
							:timestamp => Time.now.to_f,
							:method => method.to_s,
							:model => model.to_s,
							:modelid => modelid.to_s,
							:params => params,
							:data => data,
							:actionhash => Digest::MD5.hexdigest(ownerid.to_s+method.to_s+modelid.to_s))

			log.save

			return log.id.to_s

		end
	end
end