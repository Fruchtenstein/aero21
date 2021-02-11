#!/usr/bin/ruby -W1
require 'httpclient'
require 'erb'
require 'mysql2'
require 'logger'
require 'fileutils'
require_relative './config.rb'

l = Logger.new(STDOUT)
l.info "------------ #{Time.now} -----------"
db = Mysql2::Client.new(:host => "localhost", :username => DBUSER, :password => DBPASSWD, :database => DB, :encoding => "utf8mb4")
pls = db.query("SELECT runid, summary_polyline FROM log", :as => :array).to_a
pls.each do |p|
  unless File.exists?("html/maps/m#{p[0]}.png")
    if p[1] == ''
      FileUtils.cp("html/assets/notrack.png", "html/maps/m#{p[0]}.png")
    else
      url = "https://api.mapbox.com/styles/v1/mapbox/outdoors-v11/static/path-3+f44-0.5(#{ERB::Util.url_encode(p[1])})/auto/300x300?access_token=#{MAPBOX_TOKEN}"
      c = HTTPClient.new
      r = c.get(url)
      File.open("html/maps/m#{p[0]}.png", 'w') do |f|
        f.write(r.body)
      end
      l.info "+++ m#{p[0]}.png created"
      sleep 1
    end
  else
#    l.info "--- m#{p[0]}.png exists"
  end
end
l.info "xxxxxxxxxxxx #{Time.now} xxxxxxxxxxx"
