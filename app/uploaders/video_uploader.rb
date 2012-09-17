class VideoUploader < DataUploader

  def url
    if fog_public
      fog_uri = CarrierWave::Storage::Fog::File.new(self, CarrierWave::Storage::Fog.new(self), "#{store_dir}/vid.mp4").public_url
    else
      fog_uri = CarrierWave::Storage::Fog::File.new(self, CarrierWave::Storage::Fog.new(self), "#{store_dir}/vid.mp4").authenticated_url.sub(/https:\/\/#{self.fog_directory}.s3.amazonaws.com/, self.fog_host)
    end
    fog_uri
  end

  def posterurl
  	if fog_public
      fog_uri = CarrierWave::Storage::Fog::File.new(self, CarrierWave::Storage::Fog.new(self), "#{store_dir}/poster.png").public_url
	else
      fog_uri = CarrierWave::Storage::Fog::File.new(self, CarrierWave::Storage::Fog.new(self), "#{store_dir}/poster.png").authenticated_url.sub(/https:\/\/#{self.fog_directory}.s3.amazonaws.com/, self.fog_host)
	end
    fog_uri
  end

end