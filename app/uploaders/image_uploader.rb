# encoding: utf-8

class ImageUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick

  # Include the Sprockets helpers for Rails 3.1+ asset pipeline compatibility:
  # include Sprockets::Helpers::RailsHelper
  # include Sprockets::Helpers::IsolatedHelper

  # Choose what kind of storage to use for this uploader:
  # storage :file
  storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:

  version :thumb_lg do
      #process :resize_to_fill => [130,93]
      process :resize_and_pad => [200,91,'black','Center']
  end

  version :thumb_sm do
    #process :resize_to_fill => [49,46]
    process :resize_and_pad => [45,45,'black','Center']
  end

  def store_dir
    Digest::MD5.hexdigest(model.owner + model.timestamp.to_s + model.data)
  end

  def fog_directory
    "img.cla.co"
  end

  def fog_public
    true
  end

  def fog_host
    "http://img.cla.co"
  end

end
