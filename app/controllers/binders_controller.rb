class BindersController < ApplicationController
	before_filter :authenticate_teacher!

	def index
		@binders = Binder.where(:owner => current_teacher.id.to_s)

		@title = "#{current_teacher.fname} #{current_teacher.lname}'s Binders"
	end


	def new

		@binder = Binder.new

		@binders = Binder.where(:owner => current_teacher.id)

	end

	# Format is only used if Type is not folder


	def create



		@binder = Binder.new

		@binder.title = params[:title].to_s[0..60]

		#Query for parent
		@parent = Binder.where()

		#@permissions = verifypermissions(@parent)

		#@perlevel = determineperlevel(@parent.id.to_s, @permissions)

		@binder.save

		redirect_to binder_path(@binder)

	end

	def show

		@children = Binder.where(:parent["id"] => params[:id])

	end


#Fuck this shit for now
=begin
	def updatetitle

		@title = params[:title]

		if @title != ''
			if @title.length > 60
				#The title you entered is too long
			end
		else
			#Forgot to enter title
		end

		@binder = Binder.find(params[:id])

		@permissions = verifypermissions(@binder)
		@perlevel = determineperlevel(params[:id], @permissions)

		if @perlevel == 2

			@binder.title = @title[0..60]

			@binder.save


			#If folder, update children
			if @binder.type = 1

				#Update :parent fields of direct children
				@children = Binder.where(:parent["id"] => @binder.id)

				@children.each do |child|

					child.parent["title"] = @title[0..60]
					child.save
				
				end

				#Update :parents field of children
				@children = Binder.where()

				@children.each do |child|

					child.parents["title"] = @title[0..60]
					child.save

				end



			end

			return true

		else
			
			#Not the right permissions

		end

	end

	def verifypermissions(bindobj)

		@isowner = false
		@localauth = 0
		@folderloc = 0
		@publicauth = 0

		@binder = bindobj

		@uid = current_teacher.id.to_s

		#Check if current user is owner
		if(@binder.owner == @uid)
			@isowner = true
		else

			@binder.parent_permissions.each do |pper|
				
				if pper.type == 1

					if pper.shared_id == @uid

						if pper.auth_level > @localauth

							@localauth = pper.auth_level

							@findex = @binder.parents.index(pper.folder_id)

							@folderloc = @folderloc < @findex ? @findex : @folderloc

						end


					end


				#Check if authorized
				elsif pper.type == 2

					if pper.shared_id.include?(params[:courses])

						if pper.auth_level > @localauth

							@localauth = pper.auth_level

							@findex = @binder.parents.index(pper.folder_id)

							@folderloc = @folderloc < @findex ? @findex : @folderloc

						end

					end


				#Check if shared publicly
				elsif pper.type == 3
					
					@publicauth = 1


					@findex = @binder.parents.index(pper.folder_id)

					@folderloc = @folderloc < @findex ? @findex : @folderloc


				end

			# end @binder.parent_permissions.each do |pper|
			end

			#Check local permissions
			@binder.permissions.each do |per|

				if per.type == 1

					if per.shared_id == @uid

						if per.auth_level > @localauth

							@localauth = per.auth_level

							@findex = @binder.parents.length

							@folderloc = @folderloc < @findex ? @findex : @folderloc

						end

					end

				elsif per.type == 2

					if per.shared_id.include?(params[:courses])

						if per.auth_level > @localauth

							@localauth = per.auth_level

							@findex = @binder.parents.length

							@folderloc = @folderloc < @findex ? @findex : @folderloc

						end

					end

				elsif per.type == 3

					@publicauth = 1

					if per.auth_level > @localauth

						@localauth = per.auth_level

						@findex = @binder.parents.length

						@folderloc = @folderloc < @findex ? @findex : @folderloc

					end

				end

			end

		end

		@result = {"isowner" => @isowner, "localauth" => @localauth, "folderloc" => @folderloc, "publicauth" => @publicauth}

		return @result

	end


	def determineperlevel(objid, perobj)

		@level = 0

		if perobj["isowner"] == 1
			@level = 2 # Read/write
		elsif perobj["localauth"] != 0

			if perobj["localauth"] == 2
				@level = 2 # Read/write
			elsif perobj["localauth"] == 1
				@level = 1 # Read only
			end

		elsif perobj["publicauth"] == 1
			@level = 1
		end


		if objid == 0
			@level = 2
		end

		return @level

	end


	def verifypublic

		@binder = Binder.find(params[:id])

		@binder.parent_permissions.each do |pper|

			if pper.type == 3
				return true
			end
		end

		@binder.permissions.each do |per|

			if per.type == 3
				return true
			end
		end

		return false

	end
=end
end