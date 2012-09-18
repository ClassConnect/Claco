class ZencoderCallbacksController < ApplicationController



# 2012-09-17T02:05:11+00:00 app[web.1]: Started POST "/zcb" for 50.23.89.167 at 2012-09-17 02:05:11 +0000
# 2012-09-17T02:05:11+00:00 app[web.1]: Processing by ZencoderCallbacksController#processed as HTML
# 2012-09-17T02:05:11+00:00 app[web.1]:   Parameters: {"output"=>{"video_bitrate_in_kbps"=>1425, "label"=>nil, "channels"=>"2", "total_bitrate_in_kbps"=>1527, "audio_sample_rate"=>44100, "video_codec"=>"h264", "audio_bitrate_in_kbps"=>102, "frame_rate"=>25.0, "md5_checksum"=>nil, "width"=>854, "format"=>"mpeg4", "url"=>"http://cdn.cla.co.s3.amazonaws.com/0e4d6cce0796b6e740cb32d9d2e6890f/vid.mp4", "audio_codec"=>"aac", "height"=>480, "duration_in_ms"=>5000, "id"=>50965714, "file_size_in_bytes"=>972586, "state"=>"finished"}, "input"=>{"video_bitrate_in_kbps"=>852, "channels"=>"2", "total_bitrate_in_kbps"=>938, "audio_sample_rate"=>44100, "video_codec"=>"h264", "audio_bitrate_in_kbps"=>86, "frame_rate"=>25.0, "md5_checksum"=>nil, "width"=>854, "format"=>"mpeg4", "audio_codec"=>"aac", "height"=>480, "duration_in_ms"=>1399698, "id"=>26683356, "state"=>"finished", "file_size_in_bytes"=>165310873}, "job"=>{"test"=>true, "pass_through"=>nil, "submitted_at"=>"2012-09-17T02:04:29Z", "updated_at"=>"2012-09-17T02:05:09Z", "created_at"=>"2012-09-17T02:04:29Z",
# 2012-09-17T02:05:11+00:00 app[web.1]:  "id"=>26689667, "state"=>"finished"}, "zencoder_callback"=>{"output"=>{"video_bitrate_in_kbps"=>1425, "label"=>nil, "channels"=>"2", "total_bitrate_in_kbps"=>1527, "audio_sample_rate"=>44100, "video_codec"=>"h264", "audio_bitrate_in_kbps"=>102, "frame_rate"=>25.0, "md5_checksum"=>nil, "width"=>854, "format"=>"mpeg4", "url"=>"http://cdn.cla.co.s3.amazonaws.com/0e4d6cce0796b6e740cb32d9d2e6890f/vid.mp4", "audio_codec"=>"aac", "height"=>480, "duration_in_ms"=>5000, "id"=>50965714, "file_size_in_bytes"=>972586, "state"=>"finished"}, "input"=>{"video_bitrate_in_kbps"=>852, "channels"=>"2", "total_bitrate_in_kbps"=>938, "audio_sample_rate"=>44100, "video_codec"=>"h264", "audio_bitrate_in_kbps"=>86, "frame_rate"=>25.0, "md5_checksum"=>nil, "width"=>854, "format"=>"mpeg4", "audio_codec"=>"aac", "height"=>480, "duration_in_ms"=>1399698, "id"=>26683356, "state"=>"finished", "file_size_in_bytes"=>165310873}, "job"=>{"test"=>true, "pass_through"=>nil, "submitted_at"=>"2012-09-17T02:04:29Z", "updated_at"=>"2012-09-17T02:
# 2012-09-17T02:05:11+00:00 app[web.1]: 05:09Z", "created_at"=>"2012-09-17T02:04:29Z", "id"=>26689667, "state"=>"finished"}, "controller"=>"zencoder_callbacks", "action"=>"processed"}}


 # {"output"=>{"video_bitrate_in_kbps"=>1425, "label"=>nil, "channels"=>"2", "total_bitrate_in_kbps"=>1527, "audio_sample_rate"=>44100, "video_codec"=>"h264", "audio_bitrate_in_kbps"=>102, "frame_rate"=>25.0, "md5_checksum"=>nil, "width"=>854, "format"=>"mpeg4", "url"=>"http://cdn.cla.co.s3.amazonaws.com/0e4d6cce0796b6e740cb32d9d2e6890f/vid.mp4", "audio_codec"=>"aac", "height"=>480, "duration_in_ms"=>5000, "id"=>50965714, "file_size_in_bytes"=>972586, "state"=>"finished"}, "input"=>{"video_bitrate_in_kbps"=>852, "channels"=>"2", "total_bitrate_in_kbps"=>938, "audio_sample_rate"=>44100, "video_codec"=>"h264", "audio_bitrate_in_kbps"=>86, "frame_rate"=>25.0, "md5_checksum"=>nil, "width"=>854, "format"=>"mpeg4", "audio_codec"=>"aac", "height"=>480, "duration_in_ms"=>1399698, "id"=>26683356, "state"=>"finished", "file_size_in_bytes"=>165310873}, "job"=>{"test"=>true, "pass_through"=>nil, "submitted_at"=>"2012-09-17T02:04:29Z", "updated_at"=>"2012-09-17T02:05:09Z", "created_at"=>"2012-09-17T02:04:29Z", "id"=>26689667, "state"=>"finished"}, "zencoder_callback"=>{"output"=>{"video_bitrate_in_kbps"=>1425, "label"=>nil, "channels"=>"2", "total_bitrate_in_kbps"=>1527, "audio_sample_rate"=>44100, "video_codec"=>"h264", "audio_bitrate_in_kbps"=>102, "frame_rate"=>25.0, "md5_checksum"=>nil, "width"=>854, "format"=>"mpeg4", "url"=>"http://cdn.cla.co.s3.amazonaws.com/0e4d6cce0796b6e740cb32d9d2e6890f/vid.mp4", "audio_codec"=>"aac", "height"=>480, "duration_in_ms"=>5000, "id"=>50965714, "file_size_in_bytes"=>972586, "state"=>"finished"}, "input"=>{"video_bitrate_in_kbps"=>852, "channels"=>"2", "total_bitrate_in_kbps"=>938, "audio_sample_rate"=>44100, "video_codec"=>"h264", "audio_bitrate_in_kbps"=>86, "frame_rate"=>25.0, "md5_checksum"=>nil, "width"=>854, "format"=>"mpeg4", "audio_codec"=>"aac", "height"=>480, "duration_in_ms"=>1399698, "id"=>26683356, "state"=>"finished", "file_size_in_bytes"=>165310873}, "job"=>{"test"=>true, "pass_through"=>nil, "submitted_at"=>"2012-09-17T02:04:29Z", "updated_at"=>"2012-09-17T02:05:09Z", "created_at"=>"2012-09-17T02:04:29Z", "id"=>26689667, "state"=>"finished"}, "controller"=>"zencoder_callbacks", "action"=>"processed"}}

# {"output"=>
#   {"video_bitrate_in_kbps"=>1425,
#    "label"=>nil,
#    "channels"=>"2",
#    "total_bitrate_in_kbps"=>1527,
#    "audio_sample_rate"=>44100,
#    "video_codec"=>"h264",
#    "audio_bitrate_in_kbps"=>102,
#    "frame_rate"=>25.0,
#    "md5_checksum"=>nil,
#    "width"=>854,
#    "format"=>"mpeg4",
#    "url"=>
#     "http://cdn.cla.co.s3.amazonaws.com/0e4d6cce0796b6e740cb32d9d2e6890f/vid.mp4",
#    "audio_codec"=>"aac",
#    "height"=>480,
#    "duration_in_ms"=>5000,
#    "id"=>50965714,
#    "file_size_in_bytes"=>972586,
#    "state"=>"finished"},
#  "input"=>
#   {"video_bitrate_in_kbps"=>852,
#    "channels"=>"2",
#    "total_bitrate_in_kbps"=>938,
#    "audio_sample_rate"=>44100,
#    "video_codec"=>"h264",
#    "audio_bitrate_in_kbps"=>86,
#    "frame_rate"=>25.0,
#    "md5_checksum"=>nil,
#    "width"=>854,
#    "format"=>"mpeg4",
#    "audio_codec"=>"aac",
#    "height"=>480,
#    "duration_in_ms"=>1399698,
#    "id"=>26683356,
#    "state"=>"finished",
#    "file_size_in_bytes"=>165310873},
#  "job"=>
#   {"test"=>true,
#    "pass_through"=>nil,
#    "submitted_at"=>"2012-09-17T02:04:29Z",
#    "updated_at"=>"2012-09-17T02:05:09Z",
#    "created_at"=>"2012-09-17T02:04:29Z",
#    "id"=>26689667,
#    "state"=>"finished"},
#  "zencoder_callback"=>
#   {"output"=>
#     {"video_bitrate_in_kbps"=>1425,
#      "label"=>nil,
#      "channels"=>"2",
#      "total_bitrate_in_kbps"=>1527,
#      "audio_sample_rate"=>44100,
#      "video_codec"=>"h264",
#      "audio_bitrate_in_kbps"=>102,
#      "frame_rate"=>25.0,
#      "md5_checksum"=>nil,
#      "width"=>854,
#      "format"=>"mpeg4",
#      "url"=>
#       "http://cdn.cla.co.s3.amazonaws.com/0e4d6cce0796b6e740cb32d9d2e6890f/vid.mp4",
#      "audio_codec"=>"aac",
#      "height"=>480,
#      "duration_in_ms"=>5000,
#      "id"=>50965714,
#      "file_size_in_bytes"=>972586,
#      "state"=>"finished"},
#    "input"=>
#     {"video_bitrate_in_kbps"=>852,
#      "channels"=>"2",
#      "total_bitrate_in_kbps"=>938,
#      "audio_sample_rate"=>44100,
#      "video_codec"=>"h264",
#      "audio_bitrate_in_kbps"=>86,
#      "frame_rate"=>25.0,
#      "md5_checksum"=>nil,
#      "width"=>854,
#      "format"=>"mpeg4",
#      "audio_codec"=>"aac",
#      "height"=>480,
#      "duration_in_ms"=>1399698,
#      "id"=>26683356,
#      "state"=>"finished",
#      "file_size_in_bytes"=>165310873},
#    "job"=>
#     {"test"=>true,
#      "pass_through"=>nil,
#      "submitted_at"=>"2012-09-17T02:04:29Z",
#      "updated_at"=>"2012-09-17T02:05:09Z",
#      "created_at"=>"2012-09-17T02:04:29Z",
#      "id"=>26689667,
#      "state"=>"finished"},
#    "controller"=>"zencoder_callbacks",
#    "action"=>"processed"}}

	def processed

		binder = Binder.where("versions.zendata.jobid" => params[:job]["id"]).first
		
		binder.current_version.zendata = params[:zencoder_callback]

		if params[:job]["state"] == "finished"

			binder.current_version.vidtype = "zen"

			Binder.delay(:queue => 'thumbgen').get_thumbnail_from_url(binder.id, binder.current_version.video.posterurl)

		end

		if binder.save

			render :text => "" #Send 200 back to zencoder

		else

			raise binder.errors.to_s

		end
	end

end