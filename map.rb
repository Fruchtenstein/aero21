#!/usr/bin/ruby -W1
require 'httpclient'
require 'erb'
require 'mysql2'
require_relative './config.rb'

db = Mysql2::Client.new(:host => "localhost", :username => DBUSER, :password => DBPASSWD, :database => DB, :encoding => "utf8mb4")
pls = db.query("SELECT runid, summary_polyline FROM log", :as => :array).to_a
pls.each do |p|
  puts "=== #{p[0]}"
  unless File.exists?("html/m#{p[0]}.png")
    url = "https://api.mapbox.com/styles/v1/mapbox/outdoors-v11/static/path-3+f44-0.5(#{ERB::Util.url_encode(p[1])})/auto/300x300?access_token=#{MAPBOX_TOKEN}"
    c = HTTPClient.new
    r = c.get(url)
    File.open("html/m#{p[0]}.png", 'w') do |f|
      f.write(r.body)
    end
    puts "+++ m#{p[0]}.png created"
  else
    puts "--- m#{p[0]}.png exists"
  end
  sleep 1
end
