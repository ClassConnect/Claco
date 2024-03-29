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

LG_AVATAR_FILENAME = "thumb_lg.png"
MG_AVATAR_FILENAME = "thumb_mg.png"
MD_AVATAR_FILENAME = "thumb_md.png"
SM_AVATAR_FILENAME = "thumb_sm.png"

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
MAIN_FEED_LENGTH = 50
SUBSC_FEED_LENGTH = 50
PERSONAL_FEED_LENGTH = 50

MAIN_WRAP_LENGTH = 10
SUBSC_WRAP_LENGTH = 30
PERSONAL_WRAP_LENGTH = 30

# MAIN_FEED_STORAGE = 50
# SUBSC_FEED_STORAGE = 50
# PERSONAL_FEED_STORAGE = 50

FEED_METHOD_WHITELIST = %w[createfile createcontent update forkitem favorite setpub sub unsub]
FEED_DISPLAY_BLACKLIST = %w[unsub]

FEED_ANNIHILATION_PAIRS = { 'sub'=>'unsub', 'unsub'=>'sub', 'add'=>'confremove', 'confremove'=>'add' }

FEED_COLLAPSE_TIME = 30.minutes.to_i

Zencoder.api_key = "1cf703e610abc35110dfc7e9962d53e0" if Rails.env == "development"

Zencoder.api_key = ENV['ZENCODER_API_KEY'] if Rails.env == "production"

Twitter.configure do |config|
  config.consumer_key = 'RAlHtL8ZSNBg16RaYiDBQ'
  config.consumer_secret = 'In2ol36fFfI6GRnyDZQxLpGFf1QIhMUJlFpeYG4zo'
end

SIZE_PER_INVITE = 200.megabytes
SIZE_SOFT_CAP = 10.gigabytes

# must be swapped from what exists on image server
TX_PRIVATE_KEY = "4660adcf8a7e13d2215b7596da5e6c13"
RX_PRIVATE_KEY = "0a591a51998e86c2f83fffb66f954bff"

if Rails.env == "development"
	MEDIASERVER_API_URL = 'localhost:5001/api'
	APPSERVER_API_URL = 'localhost:5000/mediaserver/thumbs'
else
	MEDIASERVER_API_URL = '184.73.195.113:5000/api'
	APPSERVER_API_URL = 'http://claco.com/mediaserver/thumbs'
end

RESERVED_BINDER_IDS = ["0", "-1", "-2"]

# dijkstra
# allows for doubling while remaining a 4B variable
INFINITY = 1<<30

# Recommendation Bitmaps

# bitmap size correlates directly with rank order

GEO_BITMAP = 0x01
FACEBOOK_BITMAP = 0x02
TWITTER_BITMAP = 0x04
SUBSC_BITMAP = 0x08
SUBJECT_BITMAP = 0x10
GRADE_BITMAP =  0x20
INVITE_BITMAP = 0x40

PREFIX_EMAIL = ['Whoa!', 'Nice!', 'Woohoo!', 'Awesome!']

USE_IMG_SERVER = true

# # Porter Stemming algorithm

# STEP_2_LIST = {
# 	'ational'=>'ate', 'tional'=>'tion', 'enci'=>'ence', 'anci'=>'ance',
# 	'izer'=>'ize', 'bli'=>'ble',
# 	'alli'=>'al', 'entli'=>'ent', 'eli'=>'e', 'ousli'=>'ous',
# 	'ization'=>'ize', 'ation'=>'ate',
# 	'ator'=>'ate', 'alism'=>'al', 'iveness'=>'ive', 'fulness'=>'ful',
# 	'ousness'=>'ous', 'aliti'=>'al',
# 	'iviti'=>'ive', 'biliti'=>'ble', 'logi'=>'log'
# }

# STEP_3_LIST = {
# 	'icate'=>'ic', 'ative'=>'', 'alize'=>'al', 'iciti'=>'ic',
# 	'ical'=>'ic', 'ful'=>'', 'ness'=>''
# }


# SUFFIX_1_REGEXP = /(
# 					ational  |
# 					tional   |
# 					enci     |
# 					anci     |
# 					izer     |
# 					bli      |
# 					alli     |
# 					entli    |
# 					eli      |
# 					ousli    |
# 					ization  |
# 					ation    |
# 					ator     |
# 					alism    |
# 					iveness  |
# 					fulness  |
# 					ousness  |
# 					aliti    |
# 					iviti    |
# 					biliti   |
# 					logi)$/x


# SUFFIX_2_REGEXP = /(
# 					al       |
# 					ance     |
# 					ence     |
# 					er       |
# 					ic       |
# 					able     |
# 					ible     |
# 					ant      |
# 					ement    |
# 					ment     |
# 					ent      |
# 					ou       |
# 					ism      |
# 					ate      |
# 					iti      |
# 					ous      |
# 					ive      |
# 					ize)$/x


# C = "[^aeiou]"         # consonant
# V = "[aeiouy]"         # vowel
# CC = "#{C}(?>[^aeiouy]*)"  # consonant sequence
# VV = "#{V}(?>[aeiou]*)"    # vowel sequence

# MGR0 = /^(#{CC})?#{VV}#{CC}/o                # [cc]vvcc... is m>0
# MEQ1 = /^(#{CC})?#{VV}#{CC}(#{VV})?$/o       # [cc]vvcc[vv] is m=1
# MGR1 = /^(#{CC})?#{VV}#{CC}#{VV}#{CC}/o      # [cc]vvccvvcc... is m>1
# VOWEL_IN_STEM   = /^(#{CC})?#{V}/o                      # vowel in stem
