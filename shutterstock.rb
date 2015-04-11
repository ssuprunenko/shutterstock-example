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
    <h1>Shutterstock Contributor Profile</h1>
    <h2>#{user['full_name']}</h2>
    <a href='mailto:#{user['email']}'>#{user['email']}</a>
  """
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

  def profile(id=@contributor_id)
    self.class.get('/contributors/' + id.to_s, @options)
  end

  def earnings
    self.class.get('/contributor/earnings', @options)
  end
end
