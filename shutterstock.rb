require 'bundler/setup'
require 'sinatra'
require 'omniauth-shutterstock-contributor'
require 'dotenv'
require 'pry'

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
  session[:name] = auth.info.name
  session[:email] = auth.info.email

  redirect :profile
end

get '/profile' do
  html =
  """
    <h1>Shutterstock Contributor Profile</h1>
    <h2>#{session[:name]}</h2>
    <a href='mailto:#{session[:email]}'>#{session[:email]}</a>
  """
  html
end
