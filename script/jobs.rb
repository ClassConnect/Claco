require File.expand_path('../../config/boot',        __FILE__)
require File.expand_path('../../config/environment', __FILE__)
Rails.logger = Logger.new($stdout)
dw = Delayed::Worker.new
dw.logger = Rails.logger
dw.start