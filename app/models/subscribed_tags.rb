class Subscribed_tags
  include Mongoid::Document

  field :grade_levels, :type => Array
  field :subjects, :type => Array
  field :standards, :type => Array
  field :other_tags, :type => Array

  embedded_in :teacher
end