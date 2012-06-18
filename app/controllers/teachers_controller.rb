class TeachersController < ApplicationController
	before_filter :authenticate_teacher!

	#/teachers
	#Lists all teachers
	def index
		@title = "Teacher Listing"
		@teachers = Teacher.all

		# do not use!  much slower than C JSON parsing variant
		#@parsed_json = ActiveSupport::JSON.decode(File.read("app/assets/json/test.json").to_s)

		# JSON.parse utilizes the C unicode library, MUCH FASTER!!!!
		@parsed_json = JSON.parse(File.read("app/assets/json/standards.json"))
	end

	#/teachers/:id
	#Teacher Profiles
	def show
		@teacher = Teacher.find(params[:id])

		@title = "#{ @teacher.full_name }'s Profile"

		@relationship = current_teacher.relationship_by_teacher_id(@teacher.id)

		@colleague_requests = current_teacher.relationships.where(:colleague_status => 2).entries

		@colleagues = current_teacher.relationships.where(:colleague_status => 3).entries

		@subscriptions = current_teacher.relationships.where(:subscribed => true).entries

		#Create info entry for teacher if not yet created
		@teacher.info = Info.new if !@teacher.info

	end

	#/editinfo
	def editinfo
		@title = "Edit your information"

		current_teacher.info = Info.new if !current_teacher.info
	end

	#PUT /updateinfo
	def updateinfo

		#@teacher = current_teacher

		#@info = @teacher.info

		#@info = current_teacher.info

		#newinfo = params[:info]

		#TODO Make sure htmlcode is not allowed in @info.bio

		current_teacher.info = Info.new if !current_teacher.info

		current_teacher.info.update_info_fields(params);

		if current_teacher.info.errors.empty?
			# no errors, return to the main profile page
			redirect_to teacher_path(current_teacher)
		else
			# remain on current page, display errors
			render 'editinfo'
		end

	end

	#/tags
	def tags
		@title = "Manage your subscribed tags"

		current_teacher.tag = Tag.new if !current_teacher.tag
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

		@relationship.subscribe()

		redirect_to teacher_path(@teacher)
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

		@affected_relationship = @teacher.relationship_by_teacher_id(current_teacher.id)

		redirect_to teacher_path(params[:id]) if !@relationship.subscribed

		if @relationship.colleague_status == 0
			# both teachers are not colleagues

			# not subscribed to current teacher and not colleagues, so delete
			@affected_relationship.delete if @affected_relationship.subscribed == false

			# not subscribed and not colleagues, so delete
			@relationship.delete
		else
			# some colleague action is pending, merely unsubscribe from the other teacher
			@relationship.unsubscribe()
		end

		redirect_to teacher_path(@teacher)

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

		#current_teacher.add_colleague(params)

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

		redirect_to teacher_path(@teacher)

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

		@relationship = current_teacher.relationship_by_teacher_id(params[:id])

		if @relationship.colleague_status == 3

			#@relationship.set_colleague_status(0)

			@affected_relationship = @teacher.relationship_by_teacher_id(current_teacher.id)

			#@affected_relationship.set_colleague_status(0)

			if @relationship.subscribed == false# and @affected_relationship.subscribed == false
				# we are not subscribed to the other teacher, so delete our relationship with them
				@relationship.delete
			else
				# we are subscribed to them, so merely unset the colleague status
				@relationship.set_colleague_status(0)
			end

			if @affected_relationship.subscribed == false
				# the other teacher is not subscribed to us, so delete their relationship with us
				@affected_relationship.delete
			else
				# they are subscribed to us, so merely unset the colleague status
				@affected_relationship.set_colleague_status(0)
			end
#			@relationship.delete if !@relationship.subscribed else @relationship.set_colleague_status(0)

#			@relationship.delete

#			@affected_relationship.delete
		end

		redirect_to teacher_path(@teacher)

	end
end
