require 'bundler/setup'
require 'sinatra'
require 'omniauth-shutterstock-contributor'
require 'dotenv'
require 'pry'
require 'httparty'

Dotenv.load

use Rack::Session::Cookie, secret: ENV['SESSION_SECRET']

use OmniAuth::Builder do
  provider :shutterstock_contributor, ENV['SHUTTERSTOCK_CLIENT_ID'], ENV['SHUTTERSTOCK_CLIENT_SECRET']
end

get '/' do
  '<a href="/auth/shutterstock_contributor">Connect with Shutterstock</a>'
end

get '/auth/:provider/callback' do
  auth = request.env['omniauth.auth']
  session[:access_token] = auth.credentials.token
  session[:contributor_id] = auth.info.contributor_id

  redirect :profile
end

get '/profile' do
  client = Shutterstock.new(session[:access_token], session[:contributor_id])
  user = client.user

  html =
  """
    <h2>#{user['full_name']}</h2>
    <a href='mailto:#{user['email']}'>#{user['email']}</a>
  """

  html << "<h2>User info:</h2>"
  user.each do |k, v|
    html << "<p><b>#{k}:</b> <span>#{v}</span></p>"
  end

  # /contributors/:id
  html << "<h2>Public profile:</h2>"
  client.profile.each do |k, v|
    html << "<p><b>#{k}:</b> <span>#{v}</span></p>"
  end

  # Collections (List Sets)
  html << "<h2>Collections:</h2>"
  client.collections.each do |set|
    html << "<li>#{set['name']}"

    set.each do |k, v|
      html << "<p><b>#{k}:</b> <span>#{v}</span></p>"
    end

    html << "</li>"
  end

  # Earnings
  html << "<h2>Earnings:</h2>"
  html << "<p>#{client.earnings}</p>"

  html
end

get '/earnings' do
  client = Shutterstock.new(session[:access_token], session[:contributor_id])
  earnings = client.earnings
  "<p>#{earnings}</p>"
end

class Shutterstock
  include HTTParty
  base_uri 'https://api.shutterstock.com/v2'

  def initialize(access_token, contributor_id=nil)
    @options = {
      headers: {
        'Content-Type'  => 'application/json',
        'User-Agent'    => 'Shutterstock Contributor Client',
        'Authorization' => "Bearer #{access_token}"
      }
    }

    @contributor_id = contributor_id
  end

  def user
    self.class.get('/user', @options)
  end

  def profile(id=@contributor_id, opts=@options)
    self.class.get("/contributors/#{id}", opts)
  end

  def earnings(opts=@options)
    self.class.get('/contributor/earnings', opts)
  end

  def collections(id=@contributor_id, opts=@options)
    self.class.get("/contributors/#{id}/collections", opts)['data']
  end
end
