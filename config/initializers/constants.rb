# config/initializers/constants.rb

# CROCODOC

CROC_API_URL = "https://crocodoc.com/api/v2"
CROC_API_TOKEN = "3QsGvCVcSyYuN9HM2edPh4ZD"

PATH_UPLOAD	   = "/document/upload"
PATH_THUMBNAIL = "/download/thumbnail"	
PATH_STATUS = "/document/status"
PATH_SESSION = "/session/create"

CROC_VALID_FILE_FORMATS = ['.doc','.docx','.pdf','.ppt','.pptx']

CROC_API_OPTIONS = {
	# Your API token
	:token => "3QsGvCVcSyYuN9HM2edPh4ZD",

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
}


# URL2PNG

URL2PNG_API_URL = 'http://api.url2png.com/v3/'
URL2PNG_API_KEY = 'P50070D83E3BF0'
URL2PNG_PRIVATE_KEY = 'S6BCFD644C1322'
URL2PNG_DEFAULT_BOUNDS = 's800x600-d3'

# YOUTUBE

YOUTUBE_IMG_URL = "http://img.youtube.com/vi/"
YOUTUBE_IMG_FILE = "/0.jpg"