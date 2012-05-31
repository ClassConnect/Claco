class Info
  include Mongoid::Document

  field :bio, :type => String
  field :website, :type => String
  field :profile_picture, :type => String

  embedded_in :teacher
end