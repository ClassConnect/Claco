class Binder
	include Mongoid::Document

	#validates :title, :presence => true

	# validate embedded document with parent document
	validates_associated :tag

	# allows submitting a nested has with attributes for the embedded tag object
	# Employee.new({ :first_name => "John", :address => { :street => "Baker St." } })
	accepts_nested_attributes_for :tag

	#File/Directory-specific Attributes
	field :owner, :type => String
	field :title, :type => String#File/directory name
	field :body, :type => String #Directory annotation
	field :type, :type => Integer # 1 = Directory, 2 = File, 3 = Lesson
	#field :permissions, :type => Array # [shared_id, type, auth_level]
	embeds_one :permisson#, validate: false

	#field :tags, :type => Array#, :default => [""] # [index, {title, owner, type}]
	field :format, :type => Integer, :default => 0 #Only used if type = 2, 1 = File, 2 = Content(link)

	#Parent
	field :parent, :type => Hash
	field :parents, :type => Array #[# => {Title, id}]
	field :parent_permissions, :type => Array #[type, folder_id, shared_id, auth_level]
	#field :parent_tags, :type => Array

	# Version control is only used if type != directory
	#Version Control
	#field :versions, :type => Array # Array(# => [id, uid, timestamp, comments_priv, comments_pub, size, ext, fork_total, recs])
	embeds_many :versions#, validate: false #Versions are only used if type = 2 or 3
	field :forked_from, :type => String
	field :fork_hash, :type => String
	field :fork_stamp, :type => String
	field :last_update, :type => Integer
	field :last_updated_by, :type => String

	#Counts
	field :files, :type => Integer
	field :folders, :type => Integer
	field :total_size, :type => Integer

	#Social
	field :likes, :type => Integer
	field :comments, :type => Array

	# tag contains both local and parent tag data
	embeds_one :tag

	# updates all data within the Tag class
	def create_new_binder(params,teacher_id)

		@parenthash = {}
		@parentsarr = []

		if params[:binder][:parent].to_s == "0"

			@parenthash = { :id 	=> params[:binder][:parent],
					:title	=> ""}

			@parentsarr = [@parenthash]

		else
			new_binder_parent = Binder.find(params[:binder][:parent])

			@parenthash = { :id 	=> params[:binder][:parent],
					:title 	=> new_binder_parent.title}

			#Grab
			@parentsarr = new_binder_parent.parents << @parenthash

		end

		#new_binder = Binder.new(:owner 		=> current_teacher.id,
		self.update_attributes(	:owner			=> teacher_id,	#current_teacher.id,
					:title 			=> params[:binder][:title].to_s[0..60],
					:parent 		=> @parenthash,
					:parents 		=> @parentsarr,
					:last_update 		=> Time.now.to_i,
					:last_updated_by	=> teacher_id,	#current_teacher.id.to_s,
					:body 			=> params[:binder][:body],
					:type 			=> 1)

		self.tag = Tag.new

		self.tag.set_binder_tags(params,new_binder_parent)

		#if params[:binder][:parent] == "0"
		#
		#else
		#	parent_binder = Binder.find(params[:binder][:parent])
		#end

	end

end

class Version
	include Mongoid::Document

	field :uid, :type => String #Owner of version
	field :timestamp, :type => Integer
	field :comments_priv, :type => Array
	field :comments_pub, :type => Array
	field :size, :type => Integer
	field :ext, :type => String
	field :fork_total, :type => Integer
	field :data, :type => String #URL

	mount_uploader :file, DataUploader

	embedded_in :binder
end

class Permission
	include Mongoid::Document

	field :shared_id, :type => String
	field :type, :type => Integer
	field :auth_level, :type => Integer

	embedded_in :binder
end

class Tag
	include Mongoid::Document

	field :grade_levels, 		:type => Array, :default => [""]
	field :subjects, 		:type => Array, :default => [""]
	field :standards, 		:type => Array, :default => [""]
	field :other, 			:type => Array, :default => [""]

	field :parent_grade_levels,	:type => Array, :default => [""]
	field :parent_subjects,		:type => Array, :default => [""]
	field :parent_standards,	:type => Array, :default => [""]
	field :parent_other,		:type => Array, :default => [""]

	embedded_in :binder

	# Class Methods

	def set_binder_tags(params,parent_binder)

		# array to be eventually passed into the :grade_levels field
		#true_checkbox_array = Array.new(20, false)
		grade_levels_checkbox_array = Array.new
		subjects_checkbox_array = Array.new
		#zero_count = 0

		# update grade_levels array
		(1..(params[:binder][:tag][:grade_levels].length-1)).each do |i|
		#(1..(params[:tag][:grade_levels].length-1)).each do |i|
			#if params[:tag][:grade_levels][i] == "0"
			#	zero_count += 1
			#else
			#	true_checkbox_array[zero_count] = true
			#end
			grade_levels_checkbox_array << params[:binder][:tag][:grade_levels][i] if params[:binder][:tag][:grade_levels][i] != "0"
			#grade_levels_checkbox_array << params[:tag][:grade_levels][i] if params[:tag][:grade_level][i] != "0"
		end

		# update subjects array
		(1..(params[:binder][:tag][:subjects].length-1)).each do |i|
		#(1..(params[:tag][:subjects].length-1)).each do |i|
			subjects_checkbox_array << params[:binder][:tag][:subjects][i] if params[:binder][:tag][:subjects][i] != "0"
			#subjects_checkbox_array << params[:tag][:subjects][i] if params[:tag][:subjects][i] != "0"
		end

		# build parent values
		# if parent_binder.id == "0"
		# THIS ROOT LEVEL IS INHERENTLY FLAWED, AND THEREFORE DANGEROUS!
		if parent_binder.nil?
			# is at root level, nothing to inherit
			parent_grade_levels_tags = [""]
			parent_subjects_tags = [""]
			parent_standards_tags = [""]
			parent_other_tags = [""]
		else
			# grab parent tags, merge into values to be inserted
			# TODO: determine if the uniq method at the end of the assignments is necessary
			parent_grade_levels_tags 	= (parent_binder.tag.grade_levels 	+ parent_binder.tag.parent_grade_levels).uniq
			parent_subjects_tags 		= (parent_binder.tag.subjects 		+ parent_binder.tag.parent_subjects).uniq
			parent_standards_tags 		= (parent_binder.tag.standards 		+ parent_binder.tag.parent_standards).uniq
			parent_other_tags		= (parent_binder.tag.other 		+ parent_binder.tag.parent_other).uniq
		end

		self.update_attributes(	:grade_levels 		=> grade_levels_checkbox_array,
					:subjects 		=> subjects_checkbox_array,
					:standards 		=> params[:binder][:tag][:standards].downcase.split.uniq,
					:other 			=> params[:binder][:tag][:other].downcase.split.uniq,
					:parent_grade_levels 	=> parent_grade_levels_tags,
					:parent_subjects 	=> parent_subjects_tags,
					:parent_standards 	=> parent_standards_tags,
					:parent_other 		=> parent_other_tags)

	end

end
