CarrierWave.configure do |config|
  config.fog_credentials = {
    :provider               => 'AWS',       # required
    :aws_access_key_id      => 'AKIAIBZWYREXRVNLTJZQ',       # required
    :aws_secret_access_key  => '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'       # required
  }

  config.max_file_size = 200.megabytes

end