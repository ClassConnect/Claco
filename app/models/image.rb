class Image
	include Mongoid::Document

	field :title,		:type => String
	field :filename,	:type => String
	field :filetype,	:type => String
	field :class,		:type => Integer
	field :dimensions,	:type => Hash, 	:default => {:width => -1, :height => -1}

	field :image_hash,	:type => String

	# file id from which the image was generated, should not be self-referential
	field :parent_file,	:type => String

	mount_uploader :fullimage, ImageUploader
	mount_uploader :thumbnail_lg, ImageUploader
	mount_uploader :thumbnail_sm, ImageUploader

	#AWS:S3 shit




end
