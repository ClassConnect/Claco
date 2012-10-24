class Explore
	include Mongoid::Document

	field :issue, :type => Integer
	field :published, :type => Boolean, :default => false

	scope :published_issues, where(:published => true)

	embeds_many :categories

	# validates :issue, unique: true, presence: true
	validates_presence_of :issue
	validates_uniqueness_of :issue

	after_initialize do

		self.issue = Explore.next_issue_number if self.issue.nil?

	end

	def published?
		published
	end

	def publish!
		self.update_attributes(publish: true)
	end

	def self.find_by_issue(issue)

		exp = Explore.where(:issue => issue.to_i).first

		raise Mongoid::Errors::DocumentNotFound.new(Explore, issue.to_i) if exp.nil?

		return exp

	end

	def find_category(category)

		cat = self.categories.where(:name => category).first

		raise Mongoid::Errors::DocumentNotFound.new(Category, category) if cat.nil?

		return cat

	end

	def self.next_issue_number

		exp = Explore.order_by([:issue, :asc]).last

		return exp.nil? ? 1 : exp.issue + 1

	end

	def self.current_issue

		Explore.published_issues.order_by([:issue, :asc]).last

	end

end

class Category
	include Mongoid::Document

	field :name, :type => String
	field :binders, :type => Array, :default => []

	embedded_in :explore

	validates_uniqueness_of :name

	def find_binders
		self.binders.map{|b|Binder.find(b)}
	end
end