require 'sinatra'
require 'net/http'
require 'uri'
require 'json'
require 'mysql2'
require_relative 'config.rb'

enable :sessions
set :server, 'thin'
set :port => 28538, :bind => '127.0.0.1'

get '/2021' do
    erb :r2021
end

get '/reg1' do
    puts "========= reg1"
    if request['code'].nil?
        puts "No code"
        erb :reg1fail
    else
        begin
            retries ||= 0
            puts "code is #{request['code']}"
            uri = URI.parse("https://www.strava.com")
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            p "REQ IS: /oauth/token?client_id=#{CLIENT_ID}&client_secret=#{CLIENT_SECRET}&code=#{request['code']}&grant_type=authorization_code"
            rq = Net::HTTP::Post.new("/oauth/token?client_id=#{CLIENT_ID}&client_secret=#{CLIENT_SECRET}&code=#{request['code']}&grant_type=authorization_code")
            response = http.request(rq)
        rescue => e
            puts 'Strava error, retry:', $!, $@
            sleep 1
            retry if (retries += 1) < 3
        end
        j = JSON.parse(response.body)
        puts "TOKENRES: #{j}"
        session[:sid]=j['athlete']['id']
        session[:uname]=j['athlete']['username'] || ''
        session[:fname]=j['athlete']['firstname'] || ''
        session[:lname]=j['athlete']['lastname'] || ''
        session[:city]=j['athlete']['city'] || ''
        session[:state]=j['athlete']['state'] || ''
        session[:country]=j['athlete']['country'] || ''
        session[:sex]=j['athlete']['sex']=='F' ? 0 : 1
        session[:acctoken]=j['access_token']
        session[:reftoken]=j['refresh_token']
        #db = SQLite3::Database.new("../aero20/2020.db")
        db = Mysql2::Client.new(:host => "localhost", :username => DBUSER, :password => DBPASSWD, :database => DB, :encoding => "utf8mb4")
        email, volume = db.query("select email, goal from runners where runnerid=#{j['athlete']['id']}", :as => :array).each[0]
        p "OLDDATA: #{email}, #{volume}"
        session[:email]=email
        session[:volume]=volume
        erb :reg01
    end
end

get '/reg2' do
    begin
        puts "=========== reg2"
        p :locals
        retries ||= 0
#        db = SQLite3::Database.new("../aero20/2020.db")
        db = Mysql2::Client.new(:host => "localhost", :username => DBUSER, :password => DBPASSWD, :database => DB, :encoding => "utf8mb4")
        fullname="#{params[:fname]} #{params[:lname]}" || ''
        city = session[:city] || ''
        state = session[:state] || ''
        country = session[:country] || ''
        uname = session[:uname] || ''
        p("REPLACE INTO runners VALUES (#{session[:sid]},'#{db.escape(fullname)}', '#{db.escape(uname)}', '#{params[:email]}', 0, #{params[:volume].to_i}, #{session[:sex]}, '#{session[:acctoken]}', '#{session[:reftoken]}', '#{db.escape(city)}', '#{db.escape(state)}', '#{db.escape(country)}')")
        db.query("REPLACE INTO runners VALUES (#{session[:sid]},'#{db.escape(fullname)}', '#{db.escape(uname)}', '#{params[:email]}', 0, #{params[:volume].to_i}, #{session[:sex]}, '#{session[:acctoken]}', '#{session[:reftoken]}', '#{db.escape(city)}', '#{db.escape(state)}', '#{db.escape(country)}')")

        d = db.query("SELECT * FROM runners WHERE runnerid=#{session[:sid]}", :as => :array).each[0]
        p "INS/REPL RES: #{d}"
        session[:fullname]=d[1]
        session[:email]=d[3]
        session[:sid]=d[0]
        session[:uname]=d[2]
        session[:volume]=d[5]
        db.close
        erb :reg02
    rescue => e
        puts 'db error, retry:', $!, $@
        sleep 1
        retry if (retries += 1) < 3
    end
end

get '/gudsqap' do
    "Hi, #{session['name']}, got gudsqap: #{request['code']}"
end

get '/aero' do
    redirect 'http://aerobia.ru'
end

