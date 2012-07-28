CarrierWave.configure do |config|
  config.fog_credentials = {
    :provider               => 'AWS',       # required
    :aws_access_key_id      => 'AKIAIBZWYREXRVNLTJZQ',       # required
    :aws_secret_access_key  => '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'       # required
  }
#  config.fog_directory  = 'claco'                     # required
#  config.fog_public     = false                                   # optional, defaults to true
#  config.fog_host       = 'https://assets.example.com'            # optional, defaults to nil
#  config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}  # optional, defaults to {}
end