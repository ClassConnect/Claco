class TeachersController < ApplicationController
	before_filter :authenticate_teacher!

	#/teachers
	#Lists all teachers
	def index
		@title = "Teacher Listing"
		@teachers = Teacher.all
	end

	#/teachers/:id
	#Teacher Profiles
	def show
		@teacher = Teacher.find(params[:id])

		@title = "#{ @teacher.full_name }'s Profile"

		#Create info for teacher if not yet created
		if !@teacher.info
			@teacher.info = Info.new

		end

	end

	#/editinfo
	def editinfo
		@title = "Edit your information"

		if !current_teacher.info
			current_teacher.info = Info.new
		end
	end

	#PUT /updateinfo
	def updateinfo

		#@teacher = current_teacher

		#@info = @teacher.info

		#@info = current_teacher.info

		#newinfo = params[:info]

		#Make sure htmlcode is not allowed in @info.bio

		if !current_teacher.info
			current_teacher.info = Info.new
		end

		current_teacher.info.update_info_fields(params);

		if current_teacher.info.errors.empty?
			redirect_to teacher_path(current_teacher)
		else
			render 'editinfo'
		end

	end

	#/tags
	def tags
		@title = "Manage your subscribed tags"

		if !current_teacher.tag
			current_teacher.tag = Tag.new

			current_teacher.tag.save
		end
	end

	#PUT /updatetags
	def updatetags

		current_teacher.tag.update_tag_fields(params)

		redirect_to tags_path
	end

	# this function is no longer called:

	#/sub/:id
#	#link to subscribe to :id
#	def sub

#		#Prevent subscription to self
#		if params[:id] == current_teacher.id.to_s
#			redirect_to teacher_path(current_teacher) and return
#		end

#		@teacher = Teacher.find(params[:id])

#		#@relationship = current_teacher.relationships.find_or_initialize_by(:user_id => params[:id])
#		@relationship = current_teacher.relationship_by_teacher_id(params[:id])

#		if @relationship.subscribed
#			redirect_to teacher_path(params[:id]) and return
#		end

#		@title = "Subscribe to #{ @teacher.full_name }"

#	end

	#GET /confsub/:id <- To be changed to PUT/POST
	def confsub

		@teacher = Teacher.find(params[:id])

		@title = "You are now subscribed to #{ @teacher.full_name }"

		@relationship = current_teacher.relationship_by_teacher_id(params[:id])

		@relationship.subscribe

	end

	# this function is no longer called:

	#GET /unsub/:id
#	def unsub

#		@teacher = Teacher.find(params[:id])

#		if @teacher == current_teacher
#			redirect_to teacher_path(current_teacher) and return
#		end

#		@title = "Subscribe to #{ @teacher.full_name }"

#		@relationship = current_teacher.relationship_by_teacher_id(params[:id])

#		if !@relationship.subscribed
#			redirect_to teacher_path(params[:id]) and return
#		end

#	end

	#GET /confunsub/:id
	def confunsub

		@teacher = Teacher.find(params[:id])

		@relationship = current_teacher.relationship_by_teacher_id(params[:id])

		if !@relationship.subscribed
			redirect_to teacher_path(params[:id])
		end

		@relationship.unsubscribe

	end

	#/subs
	def subs

		@title = "#{ current_teacher.full_name }'s Subscriptions"

		@subs = current_teacher.relationships.find(:subscribed => false)
		#@subs = current_teacher.relationships.find_unsubscribed

	end

	#Relationships Schema:
	#
	#Subscriptions:
	#When a teacher subscribes to another teacher, a new Relationship is created where .subscribed = true
	#Unsubscribing sets .subscribed = false
	#
	#If teacher1 subscribes to teacher2, and teacher2 was already subscribed to teacher1, prompt teacher1
	#if they wish to send a collegue request
	#
	#Colleagues:
	#Default status is 0 => no colleague relationship
	#Changes to 1 => pending outgoing request
	#Changes to 2 => pending incoming request
	#Changes to 3 => colleagues
	#
	#Relationship status between two colleagues will either be:
	#Both 0 or both 3, when two teachers are collegues or not colleagues, with no pending requests
	#One will be 1 and the other must be 2 when a request has been made


	# this function is no longer called:

	#Will be changed to one-step process (remove the add method and change link to form)
	#GET /add/:id
#	def add

#		#Teacher to be added
#		@teacher = Teacher.find(params[:id])

#		@title = "Add #{ @teacher.full_name } as a Colleague"

#		@relationship = current_teacher.relationship_by_teacher_id(params[:id])

#		if @relationship.colleague_status == 3
#			redirect_to teacher_path(@teacher)
#		end

#	end

	#GET /confadd/:id <= To be changed to PUT/POST
	def confadd

		#Teacher to be added
		@teacher = Teacher.find(params[:id])

		@title = "Add #{ @teacher.full_name } as a Colleague"

		@relationship = current_teacher.relationship_by_teacher_id(params[:id])

		if @relationship.colleague_status == 0 #Then the colleague_status for @teacher should also be 0

			@relationship.set_colleague_status(1)

			@affected_relationship = @teacher.relationship_by_teacher_id(current_teacher.id)

			@affected_relationship.set_colleague_status(2)

		end

		#if adding colleage due to incoming request, create colleague relationshikp
		if @relationship.colleague_status == 2

			@relationship.set_colleague_status(3)

			@affected_relationship = @teacher.relationship_by_teacher_id(current_teacher.id)

			@affected_relationship.set_colleague_status(3)
		end

	end

	# this function is no longer called:

	#Will be changed to one-step process (remove the add method and change link to form)
	#GET /remove/:id
#	def remove

#		#Teacher to be removed
#		@teacher = Teacher.find(params[:id])

#		@title = "Remove #{ @teacher.full_name } as a Colleague"

#		relationship = @teacher.relationship_by_teacher_id(current_teacher.id)


#		if !@relationship.colleague_status == 3
#			redirect_to teacher_path(@teacher)
#		end

#	end

	#GET /confremove/:id <= To be changed to PUT/POST
	def confremove

		#Teacher to be removed
		@teacher = Teacher.find(params[:id])

		@title = "Remove #{ @teacher.full_name } as a Colleague"

		@relationship = @teacher.relationship_by_teacher_id(params[:id])

		if @relationship.colleague_status == 3

			@relationship.set_colleague_status(0)

			@affected_relationship = @teacher.relationship_by_teacher_id(current_teacher.id)

			@affected_relationship.set_colleague_status(0)

		else
			redirect_to teacher_path(@teacher)
		end

	end

end
