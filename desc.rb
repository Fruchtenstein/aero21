#!/usr/bin/ruby -W0
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

conn = HTTPClient.new
db = Mysql2::Client.new(:host => "localhost", :username => DBUSER, :password => DBPASSWD, :database => DB, :encoding => "utf8mb4")
desc_url = "https://www.strava.com/api/v3/activities"

get_runs = db.prepare("SELECT runid FROM log WHERE runnerid=? AND date>'#{3.days.ago.to_s(:db)}'")
set_desc = db.prepare("UPDATE log SET description=? WHERE runid=?")

db.query("SELECT runnerid, reftoken, runnername, teamid FROM runners WHERE reftoken IS NOT NULL", :as => :array).each do |r|
  rid, reftoken, rname, tid = r 
  l.info "#{rid}: #{rname}"
  runs = get_runs.execute(rid, :as => :array).to_a
  l.info runs
  if runs.length > 0
    token = auth(reftoken)
    h = {"Authorization" => "Bearer #{token}"}
    runs.each do |run|
      l.info run
      id = run[0]
      desc_resp = conn.get("#{desc_url}/#{id}", {"include_all_efforts" => 'false'}, h)
      if desc_resp.status == 200
        l.info ">>>>>>>>>>> got description for #{id}"
        activity = JSON.parse(desc_resp.content)
        description = activity['description'] || ''
        set_desc.execute(description, id)
        puts description
      else
        l.error "<<<<<<<<<<< Failed to get description for #{id}"
      end
    end
  end
end
