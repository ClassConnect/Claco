# encoding: utf-8

# require 'carrierwave/processing/mini_magick'

class AvatarUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  #include CarrierWave::RMagick
  #include CarrierWave::MiniMagick

  # Include the Sprockets helpers for Rails 3.1+ asset pipeline compatibility:
  # include Sprockets::Helpers::RailsHelper
  # include Sprockets::Helpers::IsolatedHelper

  # Choose what kind of storage to use for this uploader:
  # storage :file
  storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
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

  def extension_white_list
    %w(jpg jpeg gif png)
  end


end
