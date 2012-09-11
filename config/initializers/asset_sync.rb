AssetSync.configure do |config|
  config.fog_provider = 'AWS'
  config.aws_access_key_id = 'AKIAIBZWYREXRVNLTJZQ'
  config.aws_secret_access_key = '/gL7am3y4Fo5IOeX5s35cs9C3Vrp6R4cBD11eJTv'
  config.fog_directory = "static.cla.co"
  
  # Increase upload performance by configuring your region
  # config.fog_region = 'eu-west-1'
  #
  # Don't delete files from the store
  config.existing_remote_files = "keep"
  #
  # Automatically replace files with their equivalent gzip compressed version
  # config.gzip_compression = true
  #
  # Use the Rails generated 'manifest.yml' file to produce the list of files to 
  # upload instead of searching the assets directory.
  config.manifest = true
  #
  # Fail silently.  Useful for environments such as Heroku
  config.fail_silently = true
end