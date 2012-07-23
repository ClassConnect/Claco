# encoding: utf-8

class ImageUploader < CarrierWave::Uploader::Base


################################# EXAMPLE ################################


# class MyUploader < CarrierWave::Uploader::Base
#   include CarrierWave::RMagick

#   process :resize_to_fit => [800, 800]

#   version :thumb do
#     process :resize_to_fill => [200,200]
#   end

# end
# When this uploader is used, an uploaded image would be scaled 
# to be no larger than 800 by 800 pixels. A version called thumb 
# is then created, which is scaled and cropped to exactly 200 by 
# 200 pixels. The uploader could be used like this:

# uploader = AvatarUploader.new
# uploader.store!(my_file)                              # size: 1024x768

# uploader.url # => '/url/to/my_file.png'               # size: 800x600
# uploader.thumb.url # => '/url/to/thumb_my_file.png'   # size: 200x200


##########################################################################


  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick

  # Include the Sprockets helpers for Rails 3.1+ asset pipeline compatibility:
  # include Sprockets::Helpers::RailsHelper
  # include Sprockets::Helpers::IsolatedHelper

  # Choose what kind of storage to use for this uploader:
  storage :file
  # storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  version :thumb_lg do
    #process :resize_to_fill => [130,93]
    process :resize_and_pad => [130,93,'black','Center']
  end

  version :thumb_sm do
    #process :resize_to_fill => [49,46]
    process :resize_and_pad => [49,46,'black','Center']
  end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process :scale => [50, 50]
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  #def extension_white_list
  #  %w(jpg jpeg gif png)
  #end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

end
