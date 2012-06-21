class Binder
	include Mongoid::Document

	validates :title, :presence => true

	#File/Directory-specific Attributes
	field :owner, :type => String
	field :title, :type => String#File/directory name
	field :body, :type => String #Directory annotation
	field :type, :type => Integer # 1 = Directory, 2 = File, 3 = Lesson
	#field :permissions, :type => Array # [shared_id, type, auth_level]
	embeds_one :permisson#, validate: false

	field :tags, :type => Array # [index, {title, owner, type}]
	field :format, :type => Integer, :default => 0 #Only used if type = 2, 1 = File, 2 = Content(link)

	#Parent
	field :parent, :type => Hash
	field :parents, :type => Array #[# => {Title, id}]
	field :parent_permissions, :type => Array #[type, folder_id, shared_id, auth_level]
	field :parent_tags, :type => Array

	# Version control is only used if type != directory
	#Version Control
	#field :versions, :type => Array # Array(# => [id, uid, timestamp, comments_priv, comments_pub, size, ext, fork_total, recs])
	#field :fork_hash, :type => String #Use Binder.id
	embeds_many :versions#, validate: false #Versions are only used if type = 2 or 3
	field :forked_from, :type => String
	field :fork_stamp, :type => Integer
	field :fork_total, :type => Integer, :default => 0
	field :last_update, :type => Integer
	field :last_updated_by, :type => String

	#Counts
	field :files, :type => Integer, :default => 0
	field :folders, :type => Integer, :default => 0
	field :total_size, :type => Integer, :default => 0

	#Social
	field :likes, :type => Integer
	field :comments, :type => Array

	def current_version

		self.versions.each do |v|
			return v if v.active
		end

		return self.versions.sort_by {|v| v.timestamp}.last

	end

end

class Version
	include Mongoid::Document

	field :uid, :type => String #Owner of version
	field :timestamp, :type => Integer
	field :comments_priv, :type => Array
	field :comments_pub, :type => Array
	field :size, :type => Integer, :default => 0
	field :ext, :type => String
	field :data, :type => String #URL
	field :active, :type => Boolean, :default => false

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