# encoding: utf-8

class ImageUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  include CarrierWave::RMagick
  # include CarrierWave::MiniMagick

  # Include the Sprockets helpers for Rails 3.1+ asset pipeline compatibility:
  # include Sprockets::Helpers::RailsHelper
  # include Sprockets::Helpers::IsolatedHelper

  # Choose what kind of storage to use for this uploader:
  # storage :file
  storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:

  version :contentview do
    process resize_to_fill: [700, nil]

  end

  # version :thumb_lg do
  #     #process :resize_and_pad => [200,91,'black','Center']
  #     process :testproc
  # end
  #version
  #process :resize_to_fill => [600,600]

  #process :smart_thumbnail

  # version :thumb_sm do
  #   #process :resize_to_fill => [45,45]
  #   process :resize_and_pad => [45,45,'black']#,'Center']
  # end

  # def testproc

  #   manipulate! do |img|
  #     img = img.sepiatone
  #   end

  # end

  version :smart_thumb do
    process :resize_to_fit => [600,600]
    process :smart_thumbnail
    #process :resize_and_pad => [200,91,'black']
  end

 #include CarrierWave::RMagick

  version :thumb_lg, :from_version => :smart_thumb do
    #include CarrierWave::RMagick
    #process :smart_thumbnail => [[200,91]]
    #process :resize_and_pad => [200,91,'black']
    process :resize_to_fill => [200,91]
  end

  version :thumb_sm, :from_version => :smart_thumb do
    #include CarrierWave::RMagick
    #process :resize_to_fill => [45,45]
    #process :resize_and_pad => [45,45,'black']#,'Center']
    process :resize_to_fill => [45,45]
  end


  # def smart_thumbnail(dims = ["",""])
  #   manipulate! do |origimg|
  #     origimg = origimg.resize_and_pad(200,91,'black','Center')
  #   end
  # end


  def store_dir
    Digest::MD5.hexdigest(model.owner + model.timestamp.to_s + model.data)
  end

  def fog_directory
    "img.cla.co"
  end

  def fog_public
    true
  end

  def fog_host
    "http://img.cla.co"
  end

protected

  def smart_thumbnail(dims = ["",""])

    #Rails.logger.debug "Model Class: #{model.class.to_s}"
    #Rails.logger.debug "Thumbnailgen: #{model.inspect.to_s}"
    #Rails.logger.debug "Thumbnailgen: #{model[:thumbnailgen].to_s}"

    case model[:thumbnailgen].to_i
    when 0

      #include CarrierWave::RMagick

      manipulate! do |origimg|
    
        # case model.thumbnailgen.to_i
        # when 0
        #   #Rails.logger.debug("image!")
        # when 3
        #   #Rails.logger.debug("document!")
        # end

        img = origimg.edge(4)

        xcount = 0
        ycount = 0
        xsum = 0
        ysum = 0
        xsqr = 0
        ysqr = 0
        xcube = 0
        ycube = 0

        width = img.columns
        height = img.rows

        imgview = img.view(0,0,width,height)

        height.times do |y|
          #puts "new row"
          #img.columns.times do |x|
          width.times do |x|
            #if img.view(0,0,width,height)[y][x].red == 0
            pixel = imgview[y][x]
            #pixel2 = imgview2[y][x]
            #if pixel.red == 0 && pixel.green == 0 && pixel.blue == 0
              #str = str + '0'
            #else
            #if pixel.red > 32768 || pixel.green > 32768 || pixel.blue > 32768
            if pixel.red > 100 || pixel.green > 100 || pixel.blue > 100
              xcount += 1
              ycount += 1
              xsum += x
              ysum += y
              xsqr += x**2
              ysqr += y**2
              xcube += x**3
              ycube += y**3
              #str = str + '1'
            end
          end
          #puts str
          #str = ""
        end

        xcentroid = Float(xsum)/Float(xcount)
        ycentroid = Float(ysum)/Float(ycount)

        # Unused
        xvariance = (Float(xsqr)/Float(xcount))-xcentroid**2
        yvariance = (Float(ysqr)/Float(ycount))-ycentroid**2

        # Unused
        xsigma = Math.sqrt(xvariance)
        ysigma = Math.sqrt(yvariance)

        xEX3 = Float(xcube)/Float(xcount)
        yEX3 = Float(ycube)/Float(ycount)

        xskew =  Float(xEX3 - (3 * xcentroid  * xvariance)  - (xcentroid)**3)  / Float(xsigma**3)
        yskew =  Float(yEX3 - (3 * ycentroid  * yvariance)  - (ycentroid)**3)  / Float(ysigma**3)

        Rails.logger.debug "xskew: #{xskew}"
        Rails.logger.debug "yskew: #{yskew}"

        topcount = 0
        topsum = 0
        topsqr = 0
        topcube = 0
        bottomcount = 0
        bottomsum = 0
        bottomsqr = 0
        bottomcube = 0
        leftcount = 0
        leftsum = 0
        leftsqr = 0
        leftcube = 0
        rightcount = 0
        rightsum = 0
        rightsqr = 0
        rightcube = 0

        #img.rows.times do |y|
        height.times do |y|
          #puts "new row"
          #img.columns.times do |x|
          width.times do |x|
            #if img.view(0,0,width,height)[y][x].red == 0
            pixel = imgview[y][x]
            #pixel2 = imgview2[y][x]
            #if pixel.red == 0 && pixel.green == 0 && pixel.blue == 0
              #str = str + '0'
            #else
            #if pixel.red > 32768 || pixel.green > 32768 || pixel.blue > 32768
            if pixel.red > 1000 || pixel.green > 1000 || pixel.blue > 1000
              if x < xcentroid
                leftcount += 1
                leftsum += x
                leftsqr += x**2
                leftcube += x**3
              else
                rightcount += 1
                rightsum += x
                rightsqr += x**2
                rightcube += x**3
              end

              if y < ycentroid
                topcount += 1
                topsum += y
                topsqr += y**2
                topcube += y**3
              else
                bottomcount += 1
                bottomsum += y
                bottomsqr += y**2
                bottomcube += y**3
              end
            end
          end
        end

        topcentroid = Float(topsum)/Float(topcount)
        bottomcentroid = Float(bottomsum)/Float(bottomcount)
        leftcentroid = Float(leftsum)/Float(leftcount)
        rightcentroid = Float(rightsum)/Float(rightcount)

        topvariance   = (Float(topsqr)/   Float(topcount   ))-topcentroid**2
        bottomvariance  = (Float(bottomsqr)/Float(bottomcount))-bottomcentroid**2
        leftvariance  = (Float(leftsqr)/  Float(leftcount  ))-leftcentroid**2
        rightvariance   = (Float(rightsqr)/ Float(rightcount ))-rightcentroid**2

        topsigma = Math.sqrt(topvariance)
        bottomsigma = Math.sqrt(bottomvariance)
        leftsigma = Math.sqrt(leftvariance)
        rightsigma = Math.sqrt(rightvariance)

        topEX3 = Float(topcube)/Float(topcount)
        bottomEX3 = Float(bottomcube)/Float(bottomcount)
        leftEX3 = Float(leftcube)/Float(leftcount)
        rightEX3 = Float(rightcube)/Float(rightcount)

        topskew =     Float(topEX3 -    (3 * topcentroid     * topvariance)     - (topcentroid)**3)     / Float(topsigma**3)
        bottomskew =  Float(bottomEX3 - (3 * bottomcentroid  * bottomvariance)  - (bottomcentroid)**3)  / Float(bottomsigma**3)
        leftskew =    Float(leftEX3 -   (3 * leftcentroid    * leftvariance)    - (leftcentroid)**3)    / Float(leftsigma**3)
        rightskew =   Float(rightEX3 -  (3 * rightcentroid    * rightvariance)  - (rightcentroid)**3)   / Float(rightsigma**3)

        Rails.logger.debug "topskew:    #{topskew.to_s}"
        Rails.logger.debug "bottomskew: #{bottomskew.to_s}"
        Rails.logger.debug "leftskew:   #{leftskew.to_s}"
        Rails.logger.debug "rightskew:  #{rightskew.to_s}"

        topedge = Integer(topcentroid - topsigma)
        bottomedge = Integer(bottomcentroid + bottomsigma)
        leftedge = Integer(leftcentroid - leftsigma)
        rightedge = Integer(rightcentroid + rightsigma)

        Rails.logger.debug "91/200 ratio: #{Float(bottomedge-topedge)/Float(rightedge-leftedge)}"

        if Float(bottomedge-topedge)/Float(rightedge-leftedge) < 91.0/200.0
          # smartselect aspect ratio is wider than thumbnail aspect ratio, expand vertically
          y = Integer((91.0*width)/200.0 - height)

          if height - (bottomedge-topedge) < y
            # cannot fully expand to desired aspect ratio
            topedge = 0
            bottomedge = height
          else
            # sufficient space to expand
            if topedge < y/2
              # too close to top of image
              y -= topedge
              topedge = 0
              bottomedge += y
            elsif (height-bottomedge) < y/2
              # too close to bottom of image
              y -= (height-bottomedge)
              bottomedge = height
              topedge -= y
            else
              topedge -= y/2
              bottomedge += y/2
            end
          end
        else
          # smartselect aspect ratio is taller than thumbnail aspect ratio, expand horizontally
          x = Integer((200.0*height)/91.0 - width)

          if width - (rightedge-leftedge) < x
            # cannot fully expand to desired aspect ratio
            leftedge = 0
            rightedge = width
          else
            # sufficient space to expand
            if leftedge < x/2
              # too close to left of image
              x -= leftedge
              leftedge = 0
              rightedge += x
            elsif (width-rightedge) < x/2
              # too close to right of image
              x -= (width-rightedge)
              rightedge = width
              leftedge -= x
            else
              leftedge -= x/2
              rightedge += x/2
            end
          end
        end

        origimg = origimg.crop(leftedge,topedge,(rightedge-leftedge),(bottomedge-topedge))

      end
    when 1

      #include CarrierWave::RMagick

      # video
      # manipulate! do |origimg|

      #   width = origimg.columns
      #   height = origimg.rows

      #   if Float(height)/Float(width) < 91.0/200.0
      #     # image aspect ratio is wider than thumbnail aspect ratio, crop horizontally
          
      #     origimg = origimg.crop((width/2)-(200.0/2),0,width,height)
          
      #   else
      #     # image aspect ratio is taller than thumbnail aspect ratio, crop vertically
          
      #     origimg = origimg.crop(0,(height/2)-(91.0/2),width,height)

      #   end

      # end

      manipulate! do |origimg|
        origimg.resize_to_fill!(200.0,91.0,Magick::CenterGravity)
      end

    when 2

      #include CarrierWave::RMagick

      # url
      manipulate! do |origimg|

        origimg.resize_to_fill!(200.0,91.0,Magick::NorthGravity)

        # width = origimg.columns
        # height = origimg.rows

        # if Float(height)/Float(width) < 91.0/200.0
        #   # image aspect ratio is wider than thumbnail aspect ratio, crop horizontally
          
        #   origimg = origimg.crop((width/2)-(200.0/2),0,width,height)
          
        # else
        #   # image aspect ratio is taller than thumbnail aspect ratio, crop vertically
          
        #   origimg = origimg.crop(0,0,width,height)

        # end

      end
    when 3

      manipulate! do |origimg|
        origimg.resize_to_fill!(200.0,91.0,Magick::NorthGravity)
      end

      #include CarrierWave::MiniMagick

      # document


      #process :resize_and_pad => [200.0,91.0,'black',Magick::CenterGravity

      #manipulate! do |origimg|

        #grey_bg = Magick::Image.new(200.0, 91.0) do
        #         self.background_color = "#757575"
        #end

        #origimg.resize_to_fit!(200.0,91.0)
        #origimg.resize_to_fill!(200.0,91.0,Magick::NorthGravity)
        #origimg = origimg.resize_and_pad(200.0,91.0,'black',Magick::CenterGravity)

        #origimg = grey_bg.composite(origimg,Magick::CenterGravity,Magick::OverCompositeOp)

      #require 'RMagick'



      # manipulate! do |origimg|

      #   width = origimg.columns
      #   height = origimg.rows

      #   if Float(height)/Float(width) < 91.0/200.0
      #     # image aspect ratio is wider than thumbnail aspect ratio, crop horizontally
          
      #     origimg = origimg.crop((width/2)-(200.0/2),0,width,height)
          
      #   else
      #     # image aspect ratio is taller than thumbnail aspect ratio, crop vertically
          
      #     origimg = origimg.crop(0,(height/2)-(91.0/2),width,height)

      #   end

      # end

      #manipulate! do |img|

        #img = ImageList.new(img)

        #img.resize_to_fit!(200.0,91.0)

        #Rails.logger.debug "Class of img: #{img.class.to_s}"

        #img = img.from_blob(img.to_blob)

        # width = 200.0
        # height = 91.0
        # background = 'black'
        # gravity = Magick::CenterGravity

        #img.resize_to_fit!(width, height)

        #img = img.resize_and_pad(width,height,'black')

        #new_img = ::Magick::Image.new(width, height)
        #new_img = Magick::Image.new(Integer(width), Integer(height))
        # if background == :transparent
        #   filled = new_img.matte_floodfill(1, 1)
        # else
        #   filled = new_img.color_floodfill(1, 1, ::Magick::Pixel.from_color(background))
        # end
        # destroy_image(new_img)
        # filled.composite!(img, gravity, ::Magick::OverCompositeOp)
        # destroy_image(img)
        # filled = yield(filled) if block_given?
        # filled
      #end       

        #origimg = origimg.resize_and_pad(200.0,91.0,"#757575")

        # clown = Magick::ImageList.new("clown.jpg")
        # face = clown.crop(50, 15, 150, 165)
        # white_bg = Magick::Image.new(clown.columns, clown.rows)
        # clown = white_bg.composite(face, 50, 15,
        #                                Magick::OverCompositeOp)
        # clown.write('crop.jpg')

      #end

    end


  end

end
