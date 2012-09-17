class VideoUploader < DataUploader

  def url
    if fog_public
      fog_uri = CarrierWave::Storage::Fog::File.new(self, CarrierWave::Storage::Fog.new(self), "#{store_dir}/vid.mp4").public_url
    else
      fog_uri = CarrierWave::Storage::Fog::File.new(self, CarrierWave::Storage::Fog.new(self), "#{store_dir}/vid.mp4").authenticated_url
    end
    fog_uri
  end

end