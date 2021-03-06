require "bundler"
Bundler.require
Dotenv.load
enable :sessions

get "/" do
  erb :index
end

before do
  key = ENV["TWITTER_API_KEY"]
  secret = ENV["TWITTER_SECRET_KEY"]
  @twitter = TwitterOAuth::Client.new(
    consumer_key: key,
    consumer_secret: secret,
    token: session[:access_token],
    secret: session[:secret_token]
  )
end

get '/request_token' do
  callback_url = "#{base_url}/access_token"
  request_token = @twitter.request_token(oauth_callback: callback_url)
  session[:request_token] = request_token.token
  session[:request_token_secret] = request_token.secret
  redirect request_token.authorize_url
end

def base_url
  default_port = (request.scheme == "http") ? 80 : 443
  port = (request.port == default_port) ? "" : ":#{request.port.to_s}"
  "#{request.scheme}://#{request.host}#{port}"
end

get '/access_token' do
  begin
    @access_token = @twitter.authorize(session[:request_token], session[:request_token_secret], :oauth_verifier => params[:oauth_verifier])
  rescue OAuth::Unauthorized => @exception
    return erb :authorize_fail
  end

  session[:access_token] = @access_token.token
  session[:access_token_secret] = @access_token.secret
  session[:user_id] = @twitter.info['user_id']
  session[:screen_name] = @twitter.info['screen_name']
  session[:profile_image] = @twitter.info['profile_image_url_https']

  redirect '/'
end