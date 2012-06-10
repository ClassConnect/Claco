class Binder
	include Mongoid::Document

	#File/Directory-specific Attributes
	field :owner, :type => String
	field :title, :type => String #File/directory name
	field :body, :type => String #Directory annotation
	field :type, :type => Integer # 1 = Directory, 2 = Content/File
	field :permissions, :type => Array # [shared_id, type, auth_level]
	field :tags, :type => Array # [index, [title, owner, type]]
	field :format, :type => Integer #Only used if type = 2

	#Parent
	field :parent => Array #Possibly Replace with Binder.parents.last?
	field :parents, :type => Array
	field :parent_permissions, :type => Array #[type, folder_id, shared_id, auth_level]
	field :parent_tags, :type => Array

	#Version Control
	field :versions, :type => Array # Array(# => [id, uid, timestamp, comments_priv, comments_pub, size, ext, fork_total, recs])
	field :forked_from, :type => String
	field :fork_hash, :type => String
	field :fork_stamp, :type => String
	field :last_update, :type => Time
	field :lasted_updated_by, :type => String

	#Counts
	field :files, :type => Integer
	field :folders, :type => Integer
	field :total_size, :type => Integer

	#Social
	field :likes, :type => Integer
	field :comments, :type => Array

end
