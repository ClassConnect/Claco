class Relationship
  include Mongoid::Document

  field :user_id, :type => String
  field :is_subscribed, :type => Boolean, :default => true
  field :relationship_status, :type => Integer

  embedded_in :teacher
end