#!/usr/bin/ruby -W0
require 'csv'
require 'mysql2'
require 'httpclient'
require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'logger'
require_relative './config.rb'

def auth (reftoken)
    c = HTTPClient.new
    loginurl = "https://www.strava.com/oauth/token"
    data = { "client_id" => CLIENT_ID, "client_secret" => CLIENT_SECRET, "grant_type" => "refresh_token", "refresh_token" => reftoken}
    resp = c.post(loginurl, data)
    j = JSON.parse(resp.content)
    return j['access_token']
end

l = Logger.new(STDOUT)
$stdout.sync = true
now = Time.now.getutc
if now < PROLOG.begin or now > CUP.end
    l.error "#{now}: Not yet time..."
    exit
end
if now.wday.between?(1,DOW-1)
    getstart = 1.week.ago.getutc.beginning_of_week
else
    getstart = now.beginning_of_week
end
if getstart < PROLOG.begin
    getstart = PROLOG.begin
end
getend = now.end_of_week
if getend > CUP.end
    getend = CUP.end
end
l.info getstart
l.info getend
l.info now

conn = HTTPClient.new
db = Mysql2::Client.new(:host => "localhost", :username => DBUSER, :password => DBPASSWD, :database => DB, :encoding => "utf8mb4")
url = "https://www.strava.com/api/v3/athlete/activities"
l.info url
db.query("DELETE FROM log WHERE date>'#{getstart.to_s(:db)}' AND date<'#{getend.to_s(:db)}' AND NOT pin")

db.query("SELECT runnerid, runnerid, reftoken, runnername, teamid, goal FROM runners WHERE reftoken IS NOT NULL", :as => :array).each do |r|
    rid, sid, reftoken, rname, tid, goal = r 
    l.info "#{rid}, #{sid}: #{rname}"
    token = auth(reftoken)
    after = getstart.to_i
    before = getend.to_i
    d = {"after" => after, "before" => before, "per_page" => 100}
    h = {"Authorization" => "Bearer #{token}"}
    #   resp = c.post(url, {"after" => after, "before" => before, "per_page" => 300}, {"Authorization" => "Bearer #{token}"})
    resp = conn.get(url, d, h)
    i = db.prepare("INSERT IGNORE INTO log (runid, runnerid, date, distance, time, type, workout_type, commute, private, start_date_local, timezone, utc_offset, name, elapsed_time, total_elevation_gain, start_latitude, start_longitude, end_latitude, end_longitude, location_city, location_state, location_country, kudos_count, comment_count, photo_count, summary_polyline, gear_id, visibility, pin) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)")
    if resp.status == 200 then
        j = JSON.parse(resp.content)
        j.each do |run|
          l.info run
          id = run['id']
          type = run['type']
          distance = run['distance']
          start_date = Time.parse(run['start_date'])
          moving_time = run['moving_time']
          workout_type = run['workout_type'] || 0
          start_date_local = Time.parse(run['start_date_local'] || run['start_date'])
          timezone = run['timezone'] || ''
          utc_offset = run['utc_offset'] || 0
          name = run['name'] || ''
          elapsed_time = run['elapsed_time'] || ''
          total_elevation_gain = run['total_elevation_gain'] || 0.0
          start_latitude = run['start_latitude'] || 0.0
          start_longitude = run['start_longitude'] || 0.0
          end_latitude = run['end_latlng'] ? run['end_latlng'][0] : 0.0
          end_longitude = run['end_latlng'] ? run['end_latlng'][1] : 0.0
          location_city = run['location_city'] || ''
          location_state = run['location_state'] || ''
          location_country = run['location_country'] || ''
          kudos_count = run['kudos_count'] || 0
          comment_count = run['comment_count'] || 0
          photo_count = run['photo_count'] || 0
          summary_polyline = run['map']['summary_polyline'] || ''
          gear_id = run['gear_id'] || ''
          visibility = run['visibility'] || ''
          private = run['private'] ? 1 : 0
          commute = run['commute'] ? 1 : 0
          if type == 'Run' or type == 'VirtualRun'
            i.execute(id, rid, start_date, distance/1000, moving_time.to_i, type, workout_type, commute, private, start_date_local, timezone, utc_offset, name, elapsed_time, total_elevation_gain, start_latitude, start_longitude, end_latitude, end_longitude, location_city, location_state, location_country, kudos_count, comment_count, photo_count, summary_polyline, gear_id, visibility)
          end
        end
    else
        print "ERROR: response code #{resp.status}, content: #{resp.content}"
    end
end
