class TeachersController < ApplicationController
	before_filter :authenticate_teacher!
   
   #/teachers
   #Lists all teachers
   def index
      @title = "Teacher Listing"
   	@teachers = Teacher.all
   end

   #/teachers/id
   #Teacher Profiles
   def show
   	@teacher = Teacher.find(params[:id])

      @title = @teacher.title + " " + @teacher.fname + " " + @teacher.lname

      if !@teacher.info
         @teacher.info = Info.new

         @teacher.info.bio = ""
         @teacher.info.website = ""
         @teacher.info.profile_picture = ""

         @teacher.info.save
      end

   end

   #/sub/:id
   #link to subscribe to :id
   def sub
      if params[:id] == current_teacher.id
         redirect_to ("/teachers/" + current_teacher.id.to_s)
      end
      @teacher = Teacher.find(params[:id])
   end

   #/editinfo
   def editinfo
      @title = "Edit your information"

      @teacher = current_teacher
      
      @info = @teacher.info
   end

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

      redirect_to ("/teachers/" + current_teacher.id.to_s)

   end

   def tags
      @title = "Manage your subscribed tags"

      @teacher = current_teacher

      #Create tags object for current teacher if it doesn't already exist
      if !@teacher.tag

         @teacher.tag = Tag.new

         @teacher.tag.grade_levels = []
         @teacher.tag.subjects = []
         @teacher.tag.standards = []
         @teacher.tag.other_tag = []

         @teachers.tag = @teacher.tag

         @teachers.tag.save

      end

      @tag = @teacher.tag

   end

   def newsub
      if !current_teacher.relationships.find(params[:id])
         @relationship = Relationship.new

         @relationship.user_id = params[:id]

         @relationship.status = 0
      end
   end



end