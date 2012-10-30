class ExploreController < ApplicationController
	before_filter :authenticate_admin!, :only => [:issues, :create, :showissue, :createcat, :viewcat, :setcatbinders]

	###################
	# ADMIN FUNCTIONS #
	###################

	#View to list/create issues
	def admin

		@issues = Explore.all.order_by([:issue, :asc])

	end

	#Create new issue function
	def create

		exp = Explore.new

		exp.categories = Explore.current_issue.nil? ? [] : Explore.current_issue.categories

		if exp.save

			redirect_to admin_explore_issue_path(exp.issue)

		end

	end

	#View an issue, add/remove categories
	def editissue

		@issue = Explore.find_by_issue(params[:issue])

	end

	#Create a category
	def createcat

		exp = Explore.find_by_issue(params[:issue])

		exp.categories << Category.new(params[:category])

		redirect_to admin_explore_issue_path(params[:issue])

	end

	#View categories within an issue
	def editcat

		@category = Explore.find_by_issue(params[:issue]).find_category(params[:name])

	end

	#Set the binders for a given category
	def addcatbinder

		cat = Explore.find_by_issue(params[:issue]).find_category(params[:name])

		Binder.find(params[:binders]) unless params[:binders].blank?

		cat.update_attributes(	:binders => params[:binders].blank? ? cat.binders : (cat.binders << params[:binders]).uniq,
								# :filter => params[:category][:filter].downcase,
								:subtitle => params[:category][:subtitle])

		redirect_to admin_explore_categories_path(params[:issue], params[:name])

	end

	def remcatbinder

		cat = Explore.find_by_issue(params[:issue]).find_category(params[:name])

		cat.binders.delete(params[:binder])

		redirect_to admin_explore_categories_path(params[:issue], params[:name]) and return if cat.save

	end

	def destroycategory

		Explore.find_by_issue(params[:issue]).find_category(params[:name]).destroy

		redirect_to admin_explore_issue_path

	end

	def publish

		Explore.find_by_issue(params[:issue]).publish!

		redirect_to admin_explore_path

	end

	def unpublish

		Explore.find_by_issue(params[:issue]).unpublish!

		redirect_to admin_explore_path

	end

	def preview_issue

		@issue = Explore.find_by_issue(params[:issue])

		@title = "Explore Claco ##{@issue.issue}"

		@categories = @issue.categories

		@preview = true

		# @filters = @categories.map(&:filter).uniq

		render :issue

	end

	# def preview_category

	# 	@category = Explore.find_by_issue(params[:issue]).find_category(params[:name])

	# 	@title = "Explore | #{@category.name}"

	# 	@root = signed_in? ? current_teacher.binders.root_binders : []

	# 	@preview = true

	# 	render :category

	# end

	####################
	# PUBLIC FUNCTIONS #
	####################

	#/explore
	def index

		@issue = Explore.current_issue

		render "public/404.html", :status => 404 and return if @issue.nil?

		@title = "Explore Claco"

		@categories = @issue.categories

		# @filters = @categories.map(&:filter).uniq

		render :issue

	end

	# #/explore/:issue
	# def issue

	# 	@issue = Explore.published_issues.find_by_issue(params[:issue])

	# 	@title = "Explore Claco ##{@issue.issue}"

	# 	render "public/404.html", :status => 404 and return if @issue.nil?

	# 	@categories = @issue.categories

	# 	@filters = @categories.map(&:filter).uniq

	# end

	# #/explore/:issue/:category
	# def category

	# 	@category = Explore.published_issues.find_by_issue(params[:issue]).find_category(params[:name])

	# 	@title = "Explore | #{@category.name}"

	# 	@root = signed_in? ? current_teacher.binders.root_binders : []

	# 	rescue Mongoid::Errors::DocumentNotFound
	# 		render "public/404.html", :status => 404

	# end

end