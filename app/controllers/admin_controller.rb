class AdminController < ApplicationController
	before_filter :authenticate_admin!

	def sendinvite

		Invitation.new(	:from		=> "0",
						:to			=> params[:to],
						:submitted	=> Time.now.to_i).save

		redirect_to "/admin"

	end

	def invites

		@invites = Invitation.page(params[:page]).per(100)

	end

	def showinv

		@invite = Invitation.find(params[:id])

	end

	def apps

		if params[:adminq].present? && !params[:adminq].to_s.empty?

			@apps = Tire.search 'applicants' do |search|

				search.size 30

				search.query do |query|

					query.string "#{params[:adminq]}*"
				end

			end

			@apps=@apps.results.to_a

			@apps = Applicant.find(@apps.map{ |f| f.id.to_s })

		else
			@apps = Applicant.page(params[:page]).per(100)
		end

	end

	def ghost
		sign_in(:teacher, Teacher.find(params[:id]))
		redirect_to root_url
	end

	def users

		#debugger

		if params[:adminq].present? && !params[:adminq].to_s.empty?
			#@teachers = Teacher.all.tire.search(params[:query], load: true)
			@teachers = Tire.search 'teachers' do |search|
				#query do

				# number of results returned
				search.size 30

				search.query do |query|
					#string 'fname:S*'
					#query.size 15
					query.string "#{params[:adminq]}*"
				end
				#query { all } 
			end

			@teachers=@teachers.results.to_a

			if @teachers.map { |f| f.id.to_s }.include? current_teacher.id.to_s
				@teachers = @teachers.unshift @teachers.delete_at( @teachers.index { |f| f.id.to_s==current_teacher.id.to_s } )
			end

			@teachers = Teacher.find(@teachers.map{ |f| f.id.to_s })#.page(params[:page]).per(100) #.map { |f| Teacher.find(f.id.to_s) }#.page(params[:page]).per(100)

		else
			@teachers = Teacher.page(params[:page]).per(100)
		end

		#@teachers = @teachers

	end

	# Concurrency fix
	# Setting.f("sys_inv_list").v = Setting.f("sys_inv_list").v.map{|e| i = Invitation.where(:to => e["email"]).first; e["invited_at"] = i.submitted unless i.nil?; e["invited"] = true unless i.nil?; e}
	
	def sysinvlist

		@invs = Setting.f("sys_inv_list").v

	end

	def choosepibinder

		@pibinder = Setting.f("pioneer").v

	end

	def setpibinder

		Setting.f("pioneer").v = params[:binder]

		redirect_to "/admin"

	end

	def setfeatured

		Setting.f("featured").v = [] if Setting.f("featured").v.nil?

		Setting.f("featured").v = Setting.f("featured").v << params[:binder]

		redirect_to "/admin"

	end

	def choosethumbnails

		render 'admin/updatethumbnails'

	end

	def getthumbnails

		#debugger

		if params[:type]=='folder'

			begin
				binder = Binder.find(params[:binderid].to_s)
				#raise "not a folder" if binder.type != 1
			rescue
				return
			end

			thumburls = []

			begin
				thumburls << (binder.thumbimgids[0].to_s.empty? ? '' : Binder.thumb_lg(Binder.find(binder.thumbimgids[0])))
				thumburls << (binder.thumbimgids[1].to_s.empty? ? '' : Binder.thumb_sm(Binder.find(binder.thumbimgids[1])))
				thumburls << (binder.thumbimgids[2].to_s.empty? ? '' : Binder.thumb_sm(Binder.find(binder.thumbimgids[2])))
				thumburls << (binder.thumbimgids[3].to_s.empty? ? '' : Binder.thumb_sm(Binder.find(binder.thumbimgids[3])))
				thumburls << binder.thumbimgids
			rescue
				#return
			end

			respond_to do |format|
				format.json { render :json => thumburls.to_json }
			end
			return

		elsif params[:type]=='content'

			begin
				binder = Binder.find(params[:binderid].to_s)
				#raise "not a folder" if binder.type != 1
			rescue
				return
			end

			thumburls = []

			begin
				thumburls << Binder.thumb_lg(binder)
				thumburls << Binder.thumb_sm(binder)
			rescue
				return
			end

			respond_to do |format|
				format.json { render :json => thumburls.to_json }
			end
			return

		end

		respond_to do |format|
			format.json { render :json => {}.to_json }
		end

	end

	def setthumbnails

		#debugger

		begin
			binder = Binder.find(params[:binderid].to_s)
			raise "not a folder" if binder.type != 1
		rescue
			return
		end

		if params[:wipe]=='1'
			binder.update_attributes(:thumbimgids=>['','','',''])
			return
		end

		begin
			Binder.find(params[:thumb1].to_s) if !params[:thumb1].to_s.empty?
			Binder.find(params[:thumb2].to_s) if !params[:thumb2].to_s.empty?
			Binder.find(params[:thumb3].to_s) if !params[:thumb3].to_s.empty?
			Binder.find(params[:thumb4].to_s) if !params[:thumb4].to_s.empty?
		rescue
			return
		end

		begin
			binder.update_attributes(:thumbimgids => [params[:thumb1].to_s.empty? ? binder.thumbimgids[0] : params[:thumb1].to_s,
													  params[:thumb2].to_s.empty? ? binder.thumbimgids[1] : params[:thumb2].to_s,
													  params[:thumb3].to_s.empty? ? binder.thumbimgids[2] : params[:thumb3].to_s,
													  params[:thumb4].to_s.empty? ? binder.thumbimgids[3] : params[:thumb4].to_s])
		rescue
			return
		end

		respond_to do |format|
			format.json { render :json => {}.to_json }
		end

		#render 'admin/updatethumbnails'

	end

	def choosefpfeatured

		@fpfeatured = Setting.f("fpfeatured").v || []

	end

	def setfpfeatured

		Setting.f("fpfeatured").v = [] if Setting.f("fpfeatured").v.nil?

		Setting.f("fpfeatured").v = Setting.f("fpfeatured").v << {	"top" => params[:binder1],
																	"bot" => params[:binder2],
																	"time" => Time.now.to_i}

		expire_fragment('publichome')

		redirect_to "/admin"

	end

end