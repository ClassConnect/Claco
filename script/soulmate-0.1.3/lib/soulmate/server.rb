require 'sinatra/base'
require 'soulmate'
require 'rack/contrib'

module Soulmate

  class Server < Sinatra::Base
    include Helpers

    use Rack::JSONP

    before do
      content_type 'application/json', :charset => 'utf-8'
    end

    get '/' do
      MultiJson.encode({ :soulmate => Soulmate::Version::STRING, :status   => "ok" })
    end

    get '/search' do
      raise Sinatra::NotFound unless (params[:term] and params[:types] and params[:types].is_a?(Array))

      limit = (params[:limit] || 6).to_i
      types = params[:types].map { |t| normalize(t) }
      term  = params[:term]

      results = {}
      smushset = []
      retstr = '['

      types.each do |type|
        matcher = Matcher.new(type)
	matcher.matches_for_term(term, :limit => limit).each { |result| smushset << "{ label: \"#{ result['data']['label'] }\", value: \"#{ result['data']['value'] }\" }" }
      end

      smushset.uniq.each { |result| retstr += "#{result}," }

      smushset.any? ? retstr[-1] = ']' : retstr = ''

      return retstr

    end

    not_found do
      content_type 'application/json', :charset => 'utf-8'
      MultiJson.encode({ :error => "not found" })
    end

  end
end
