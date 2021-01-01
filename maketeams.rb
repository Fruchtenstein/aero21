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
ladies = Array.new(TEAMS,0)

db.query("SELECT runnerid, runnername, goal, teamid, sex FROM runners WHERE teamid!=0 ORDER BY goal DESC", :as => :array).each do |r|
    teams[r[3]-1] << [r[0],r[1],r[2]]
    goals[r[3]-1] += 7*r[2]/365
    if r[4]==0
        ladies[r[3]-1] += 1
    end
end

db.query("SELECT runnerid, runnername, goal FROM runners WHERE sex=1 AND teamid=0 ORDER BY goal DESC", :as => :array).each do |r|
  goesto = goals.index(goals.min)
  teams[goesto] << [r[0],r[1],r[2]]
  goals[goesto] += 7*r[2]/365
  db.query("UPDATE runners SET teamid=#{goesto+1} WHERE runnerid=#{r[0]}")
end

db.query("SELECT runnerid, runnername, goal FROM runners WHERE sex=0 AND teamid=0 ORDER BY goal DESC", :as => :array).each do |r|
    ladies.each_with_index do |t, i|
        if t>=2
            p "#{t}>=2"
            goals[i] = 10000
        end
    end
  goesto = goals.index(goals.min)
  p "goesto #{goesto}"
  teams[goesto] << [r[0],r[1],r[2]]
  goals[goesto] += 7*r[2]/365
  ladies[goesto] += 1
  db.query("UPDATE runners SET teamid=#{goesto+1} WHERE runnerid=#{r[0]}")
end

pp teams
goals = db.query("SELECT 7*SUM(goal)/365 FROM runners GROUP BY teamid ORDER BY teamid", :as => :array).to_a
pp goals

#pp db.execute("select teamid, runnername, goal from runners WHERE NOT runnerid=1662188 order by teamid,goal desc")
