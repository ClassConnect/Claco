class ExploreController < ApplicationController
	before_filter :authenticate_admin!, :only => [:issues, :create, :showissue, :createcat, :viewcat, :setcatbinders]

	###################
	# ADMIN FUNCTIONS #
	###################

	#View to list/create issues
	def admin

		@issues = Explore.all

	end

	#Create new issue function
	def create

		exp = Explore.new

		if exp.save

			redirect_to admin_explore_issue_path(exp.issue)

		end

	end

	#View an issue, add/remove categories
	def showissue

		@issue = Explore.find_by_issue(params[:issue])

	end

	#Create a category
	def createcat

		exp = Explore.find_by_issue(params[:issue])

		exp.categories << Category.new(params[:category])

		redirect_to admin_explore_issue_path(params[:issue])

	end

	#View categories within an issue
	def viewcat

		@category = Explore.find_by_issue(params[:issue]).find_category(params[:category])

	end

	#Set the binders for a given category
	def setcatbinders

		cat = Explore.find_by_issue(params[:issue]).find_category(params[:category])

		params[:binders].map{|id| Binder.find(id)} #Check if all binder ids are valid

		redirect_to admin_explore_categories_path(params[:issue], params[:category]) and return if cat.update_attributes(:binders => params[:binders])

	end

	def destroycategory

		Explore.find_by_issue(params[:issue]).find_category(params[:category]).destroy

		redirect_to admin_explore_issue_path

	end

	def publish

		Explore.find_by_issue(params[:issue]).publish!

		redirect_to admin_explore_path

	end

	####################
	# PUBLIC FUNCTIONS #
	####################

	#/explore
	def index

		@issue = Explore.current_issue

		@categories = @issue.categories

		render :issue

	end

	#/explore/:issue
	def issue

		@issue = Explore.find_by_issue(params[:issue])

		@categories = @issue.categories

	end

	#/explore/:issue/:category
	def category

		@category = Explore.find_by_issue(params[:issue]).find_category(params[:category])

	end

end