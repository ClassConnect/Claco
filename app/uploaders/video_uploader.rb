class VideoUploader < DataUploader

	def filename
		model.videofilename
	end

end