# config/initializers/constants.rb

# CROCODOC

CROC_API_URL = "https://crocodoc.com/api/v2"
CROC_API_TOKEN = "ROB4kYhQb0Nard6KtHZxTVC8"  #old API token: "3QsGvCVcSyYuN9HM2edPh4ZD"

PATH_UPLOAD	   = "/document/upload"
PATH_THUMBNAIL = "/download/thumbnail"	
PATH_STATUS = "/document/status"
PATH_SESSION = "/session/create"
PATH_TEXTGRAB = "/download/text"

CROC_VALID_FILE_FORMATS = %w[doc .doc docx .docx ppt .ppt pptx .pptx pdf .pdf xls .xls xlsx .xlsx]

CROC_API_OPTIONS = {
	# Your API token
	:token => "ROB4kYhQb0Nard6KtHZxTVC8",  #old API token: "3QsGvCVcSyYuN9HM2edPh4ZD",

	# When uploading in async mode, a response is returned before conversion begins.
	:async => false,

	# Documents uploaded as private can only be accessed by owners or via sessions.
	:private => false,

	# When downloading, should the document include annotations?
	:annotated => false,

	# Can users mark up the document? (Affects both #share and #get_session)
	:editable => true,

	# Whether or not a session user can download the document.
	:downloadable => true

	#TODO: add default size argument
}


# URL2PNG

URL2PNG_API_URL = 'http://api.url2png.com/v3/'
URL2PNG_API_KEY = 'P50070D83E3BF0'
URL2PNG_PRIVATE_KEY = 'S6BCFD644C1322'
URL2PNG_DEFAULT_BOUNDS = 's800x600-d3'

# YOUTUBE

YOUTUBE_IMG_URL = "http://img.youtube.com/vi/"
YOUTUBE_IMG_FILE = "/0.jpg"

# SUPPORTED DOCUMENTS 

CLACO_VALID_IMAGE_FILETYPES = %w[jpg .jpg jpeg .jpeg png .png gif .gif]
ZENCODER_SUPPORTED_VIDEO_EXTS = %w[mp4 .mp4 m4v .m4v wmv .wmv mov .mov avi .avi flv .flv mpg .mpg mpeg .mpeg 3gp .3gp 3gpp .3gpp mkv .mkv]
CLACO_SUPPORTED_THUMBNAIL_FILETYPES = %w[notebook .notebook] + CROC_VALID_FILE_FORMATS + CLACO_VALID_IMAGE_FILETYPES + ZENCODER_SUPPORTED_VIDEO_EXTS
# THUMBNAIL GENERATION
 
# Size to scale down the full image before smart thumbnail generation
IMGSCALE = 800

# Threshold for edge detection image
EDGEPIX_THRESH_PRIMARY = 100
EDGEPIX_THRESH_SECONDARY = 1000

# Content view pixel display width
CV_WIDTH = 700

# Large thumbnail dimensions
LTHUMB_W = 180.0
LTHUMB_H = 122.0

# Small thumbnail dimensions
STHUMB_W = 59.0
STHUMB_H = 50.0

# blob filedata
BLOB_FILETYPE = "png"
CV_FILENAME = "contentview.png"
LTHUMB_FILENAME = "thumb_lg.png"
STHUMB_FILENAME = "thumb_sm.png"

# crocodoc thumbs
CROC_BACKGROUND_COLOR = "#EEEEEE"
CROC_BORDER_COLOR = "#CCCCCC"

# Teachers
#AVATAR_XLDIM = 170
AVATAR_LDIM = 170
AVATAR_MGDIM = 122 # between medium and large... marge?
AVATAR_MDIM = 48
AVATAR_SDIM = 30

# Feed
MAIN_FEED_LENGTH = 30
SUBSC_FEED_LENGTH = 30
PERSONAL_FEED_LENGTH = 30

MAIN_FEED_STORAGE = 50
SUBSC_FEED_STORAGE = 50
PERSONAL_FEED_STORAGE = 50

FEED_METHOD_WHITELIST = %w[createfile createcontent update forkitem favorite setpub sub unsub]
FEED_DISPLAY_BLACKLIST = %w[unsub]

FEED_ANNIHILATION_PAIRS = { 'sub'=>'unsub', 'unsub'=>'sub', 'add'=>'confremove', 'confremove'=>'add' }

FEED_COLLAPSE_TIME = 30.minutes.to_i

Zencoder.api_key = "1cf703e610abc35110dfc7e9962d53e0" if Rails.env = "development"

Zencoder.api_key = ENV['ZENCODER_API_KEY'] if Rails.env = "production"

Twitter.configure do |config|
  config.consumer_key = 'RAlHtL8ZSNBg16RaYiDBQ'
  config.consumer_secret = 'In2ol36fFfI6GRnyDZQxLpGFf1QIhMUJlFpeYG4zo'
end

SIZE_PER_INVITE = 300.megabytes
SIZE_SOFT_CAP = 10.gigabytes