# encoding: utf-8

class DataUploader < CarrierWave::Uploader::Base
  include CarrierWaveDirect::Uploader

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  #include CarrierWave::MiniMagick

  # Include the Sprockets helpers for Rails 3.1+ asset pipeline compatibility:
  # include Sprockets::Helpers::RailsHelper
  # include Sprockets::Helpers::IsolatedHelper

  # Choose what kind of storage to use for this uploader:
  #storage :file
  # storage :fog
  # Overridden by CarrierWaveDirectUploader

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    Digest::MD5.hexdigest(model.owner + model.timestamp.to_s + model.data)
  end

  def key
    @key ||= "#{store_dir}/#{FILENAME_WILDCARD}"
  end

  def fog_directory
    if Rails.env == "production"
      "cdn.cla.co"
    else
      "rich.cla.co"
    end
  end

  def fog_public
    false
  end

  def filename
    model.filename
  end

  def fog_host
    if Rails.env == "production"
      "http://cdn.cla.co"
    else
      "http://rich.cla.co"
    end
  end

  def url
    if fog_public
      fog_uri = CarrierWave::Storage::Fog::File.new(self, CarrierWave::Storage::Fog.new(self), "#{store_dir}/#{model.filename}").public_url
    else
      fog_uri = CarrierWave::Storage::Fog::File.new(self, CarrierWave::Storage::Fog.new(self), "#{store_dir}/#{model.filename}").authenticated_url
    end
    fog_uri
  end

  def direct_fog_url
    return fog_host if model.new? && model.filename == nil

    if fog_public
      fog_uri = CarrierWave::Storage::Fog::File.new(self, CarrierWave::Storage::Fog.new(self), key).public_url
    else
      fog_uri = CarrierWave::Storage::Fog::File.new(self, CarrierWave::Storage::Fog.new(self), key).authenticated_url
    end
    fog_uri
  end

  # CarrierWave::Storage::Fog::File.new(DataUploader, CarrierWave::Storage::Fog.new(), key)

  # MIGRATION: Binder.where(:format => 1).each{|b| b.current_version.update_attributes(:filename => URI.parse(b.current_version.file.url).path.split("/").last)}

  include ActiveModel::Conversion
  extend ActiveModel::Naming
end