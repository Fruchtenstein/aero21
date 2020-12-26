#!/usr/bin/ruby -W0
require 'mysql2'
require 'pp'
require 'active_support'
require 'active_support/core_ext'
require_relative './config.rb'
TEAMS = ARGV[0].to_i
db = Mysql2::Client.new(:host => "localhost", :username => DBUSER, :password => DBPASSWD, :database => DB, :encoding => "utf8mb4")
teams = Array.new(TEAMS) {Array.new}
goals = Array.new(TEAMS,0)

db.query("SELECT runnerid, runnername, goal FROM runners WHERE NOT runnerid=1662188 AND sex=1 ORDER BY goal DESC", :as => :array).each do |r|
  goesto = goals.index(goals.min)
  teams[goesto] << [r[1],r[2]]
  goals[goesto] += 7*r[2]/365
  db.query("UPDATE runners SET teamid=#{goesto+1} WHERE runnerid=#{r[0]}")
end

db.query("SELECT runnerid, runnername, goal FROM runners WHERE NOT runnerid=1662188 AND sex=0 ORDER BY goal DESC", :as => :array).each do |r|
  goesto = goals.index(goals.min)
  teams[goesto] << [r[1],r[2]]
  goals[goesto] += 7*r[2]/365
  db.query("UPDATE runners SET teamid=#{goesto+1} WHERE runnerid=#{r[0]}")
end

pp teams
pp goals

#pp db.execute("select teamid, runnername, goal from runners WHERE NOT runnerid=1662188 order by teamid,goal desc")
