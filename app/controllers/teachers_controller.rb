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

      @title = "#{@teacher.title} #{@teacher.fname} #{@teacher.lname}'s Profile"

      #Create info for teacher if not yet created
      if !@teacher.info
         @teacher.info = Info.new

         @teacher.info.bio = ""
         @teacher.info.website = ""
         @teacher.info.profile_picture = ""

         @teacher.info.save
      end

   end

   #/editinfo
   def editinfo
      @title = "Edit your information"

      @teacher = current_teacher
      
      @info = @teacher.info
   end

   #PUT /updateinfo
   def updateinfo

      @teacher = current_teacher

      @info = @teacher.info

      #TODO: Add validation to make sure that the profile_picture is actually a link to picture,
      #or add image upload form
      #Make sure htmlcode is not allowed in @info.bio

      @info.bio = params[:info][:bio]
      @info.website = params[:info][:website]
      @info.profile_picture = params[:info][:profile_picture]
      @info.save

      redirect_to teacher_path(current_teacher)

   end

   #/tags
   def tags
      @title = "Manage your subscribed tags"

      @teacher = current_teacher

      #Create tags object for current teacher if it doesn't already exist
      if !@teacher.tag

         @teacher.tag = Tag.new

         @teacher.tag.grade_levels = [""]
         @teacher.tag.subjects = [""]
         @teacher.tag.standards = [""]
         @teacher.tag.other = [""]

         @teachers.tag.save

      end

      @tag = @teacher.tag

   end

   #PUT /updatetags
   def updatetags
      @teacher = current_teacher

      @teacher.tag.grade_levels = params[:tag][:grade_levels]

      #TODO: Don't allow/consolidate duplicate tags
      @teacher.tag.subjects = params[:tag][:subjects].split

      @teacher.tag.standards = params[:tag][:standards].split

      @teacher.tag.other = params[:tag][:other].split

      @teacher.tag.save

      redirect_to tags_path
   end

   #/sub/:id
   #link to subscribe to :id
   def sub

      #Prevent subscription to self
      if params[:id] == current_teacher.id.to_s
         redirect_to teacher_path(current_teacher) and return
      end

      @teacher = Teacher.find(params[:id])

      @relationship = current_teacher.relationships.find_or_initialize_by(:user_id => params[:id])

      if @relationship.subscribed
         redirect_to teacher_path(params[:id]) and return
      end

      @title = "Subscribe to #{@teacher.title} #{@teacher.lname}"

   end

   #GET /confsub/:id <- To be changed to PUT/POST
   def confsub

      @teacher = Teacher.find(params[:id])

      @title = "You are now subscribed to #{@teacher.title} #{@teacher.lname}"

      @relationship = current_teacher.relationships.find_or_initialize_by(:user_id => params[:id])

      #if !@relationship
      #   @relationship = Relationship.new
      #end

      @relationship.subscribed = true

      @relationship.save

   end

   #GET /unsub/:id
   def unsub

      @teacher = Teacher.find(params[:id])

      if @teacher == current_teacher
         redirect_to teacher_path(current_teacher) and return
      end

      @title = "Subscribe to #{@teacher.title} #{@teacher.lname}"

      @relationship = current_teacher.relationships.find_or_initialize_by(:user_id => params[:id])

      if !@relationship.subscribed
         redirect_to teacher_path(params[:id]) and return
      end

   end

   #GET /confunsub/:id
   def confunsub
      
      @teacher = Teacher.find(params[:id])

      @relationship = current_teacher.relationships.find_or_initialize_by(:user_id => params[:id])

      if !@relationship.subscribed
         redirect_to teacher_path(params[:id])
      end

      @relationship.subscribed = false

      @relationship.save

   end

   #/subs 
   def subs

      @title = "#{current_teacher.fname} #{current_teacher.lname}'s Subscriptions"

      @subs = current_teacher.relationships.find(:subscribed => false)

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


   #Will be changed to one-step process (remove the add method and change link to form)
   #GET /add/:id
   def add

      #Teacher to be added
      @teacher = Teacher.find(params[:id])

      @title = "Add #{@teacher.fname} #{@teacher.lname} as a Colleague"

      @relationship = current_teacher.relationships.find_or_initialize_by(:user_id => params[:id])

      if @relationship.colleague_status == 3
         redirect_to teacher_path(@teacher)
      end

   end

   #GET /confadd/:id <= To be changed to PUT/POST
   def confadd

      #Teacher to be added
      @teacher = Teacher.find(params[:id])

      @title = "Add #{@teacher.fname} #{@teacher.lname} as a Colleague"

      @relationship = current_teacher.relationships.find_or_initialize_by(:user_id => params[:id])

      if @relationship.colleague_status == 0 #Then the colleague_status for @teacher should also be 0
         @relationship.colleague_status = 1

         @relationship.save

         @effected_relationship = @teacher.relationships.find_or_initialize_by(:user_id => current_teacher.id)

         @effected_relationship.colleague_status = 2

         @effected_relationship.save
      end

      #if adding colleage due to incoming request, create colleague relationshikp
      if @relationship.colleague_status == 2
         @relationship.colleague_status = 3

         @relationship.save

         @effected_relationship = @teacher.relationships.find_or_initialize_by(:user_id => current_teacher.id)

         @effected_relationship.colleague_status = 3

         @effected_relationship.save
      end

   end


   #Will be changed to one-step process (remove the add method and change link to form)
   #GET /remove/:id
   def remove

      #Teacher to be removed
      @teacher = Teacher.find(params[:id])

      @title = "Remove #{@teacher.fname} #{@teacher.lname} as a Colleague"

      @relationship = current_teacher.relationships.find_or_initialize_by(:user_id => params[:id])


      if !@relationship.colleague_status == 3
         redirect_to teacher_path(@teacher)
      end

   end

   #GET /confremove/:id <= To be changed to PUT/POST
   def confremove

      #Teacher to be removed
      @teacher = Teacher.find(params[:id])

      @title = "Remove #{@teacher.fname} #{@teacher.lname} as a Colleague"

      @relationship = current_teacher.relationships.find_or_initialize_by(:user_id => params[:id])

      if @relationship.colleague_status == 3

         @relationship.colleague_status = 0

         @relationship.save

         @effected_relationship = @teacher.relationships.find_or_initialize_by(:user_id => current_teacher.id)

         @effected_relationship.colleague_status = 0

         @effected_relationship.save

      else
         redirect_to teacher_path(@teacher)
      end

   end

end