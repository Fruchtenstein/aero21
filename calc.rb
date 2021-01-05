#!/usr/bin/ruby -W0
require 'mysql2'
require 'active_support'
require 'active_support/core_ext'
require 'pp'
require_relative './config.rb'

def calcweek (now)
    puts ">> calcweek #{now}"
    week_number = now.to_date.strftime('%W').to_i
    db = Mysql2::Client.new(:host => "localhost", :username => DBUSER, :password => DBPASSWD, :database => DB, :encoding => "utf8mb4")
    teams = []
    (1..TEAMS).each do |t|
        num_of_runners = db.query("SELECT COUNT(*) FROM runners WHERE teamid=#{t}", :as => :array).each[0][0]
        tdist = 0
        sum_pct = 0
        db.query("SELECT runnerid, goal*7/365.0 FROM runners WHERE teamid=#{t}", :as => :array).each do |r|
            dist = db.query("SELECT COALESCE(SUM(distance),0) FROM log WHERE runnerid=#{r[0]} AND date>'#{now.beginning_of_week.to_s(:db)}' AND date<'#{now.end_of_week.to_s(:db)}'", :as => :array).each[0][0]
            goal = r[1]
            sum_pct += (dist/goal)*100
            tdist += dist
        end
        teams << [t, week_number, sum_pct/num_of_runners, tdist]
    end
    teams.sort! { |x,y| y[2] <=> x[2] }
    teams.each do |t|
        place = teams.index(t)+1
        points = 5*(TEAMS-place)
        p          "REPLACE INTO points VALUES (#{t[0]}, #{week_number}, #{points}, #{t[2]}, #{t[3]})"
        db.query("REPLACE INTO points VALUES (#{t[0]}, #{week_number}, #{points}, #{t[2]}, #{t[3]})")
        db.query("REPLACE INTO cup VALUES (#{t[0]}, #{week_number}, #{points}, #{t[2]}, #{t[3]})")
    end
end

def calcwlog(d)
    puts ">> calcwlog #{d}"
    if d.year != Time.now.year
        d = Time.new(2021, 1, 1)
        bow = d.to_s(:db)
    else
        bow = d.beginning_of_week.to_s(:db)
    end
    week_number = d.to_date.strftime('%W').to_i
    eow = d.end_of_week.to_s(:db)
    teamdist = Hash.new(0)
    teamtime = Hash.new(0)
    teamgoal = Hash.new(0)
    db = Mysql2::Client.new(:host => "localhost", :username => DBUSER, :password => DBPASSWD, :database => DB, :encoding => "utf8mb4")
    db.query("SELECT runnerid, teamid, 7*goal/365 from runners where teamid>0", :as => :array).each do |r|
        p r
      p ("SELECT COALESCE(SUM(distance),0), COALESCE(SUM(time),0) FROM log, runners WHERE log.runnerid=runners.runnerid AND log.runnerid=#{r[0]} AND date>'#{bow}' AND date<'#{eow}'")
      res = db.query("SELECT COALESCE(SUM(distance),0), COALESCE(SUM(time),0) FROM log, runners WHERE log.runnerid=runners.runnerid AND log.runnerid=#{r[0]} AND date>'#{bow}' AND date<'#{eow}'", :as => :array).each[0]
      pp "r=",r
      pp "res=", res
      db.query("REPLACE INTO wlog VALUES (#{r[0]}, #{week_number}, #{res[0]}, #{res[1]})")
      teamdist[r[1]] += res[0]
      teamtime[r[1]] += res[1]
      teamgoal[r[1]] += r[2]
    end
    p teamdist,teamtime,teamgoal
    teamdist.each do |team, distance|
      if team
        p("REPLACE INTO teamwlog VALUES (#{team}, #{week_number}, #{distance}, #{teamtime[team]}, #{teamgoal[team]})")
        db.query("REPLACE INTO teamwlog VALUES (#{team}, #{week_number}, #{distance}, #{teamtime[team]}, #{teamgoal[team]})")
      end
    end
end

def calcwonders(d)
    puts ">> calcwonders #{d}"
    if d.year != Time.now.year
        d = Time.new(2021, 1, 1)
        bow = d.to_s(:db)
    else
        bow = d.beginning_of_week.to_s(:db)
    end
    week_number = d.to_date.strftime('%W').to_i
    eow = d.end_of_week.to_s(:db)
    db = Mysql2::Client.new(:host => "localhost", :username => DBUSER, :password => DBPASSWD, :database => DB, :encoding => "utf8mb4")
    # best boy in week mileage
    p("SELECT log.runnerid r, teamid t, COALESCE(SUM(distance),0) d FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=1 AND teamid>0 GROUP BY r ORDER BY d DESC LIMIT 1")
    w = db.query("SELECT log.runnerid r, teamid t, COALESCE(SUM(distance),0) d FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=1 AND teamid>0 GROUP BY r ORDER BY d DESC LIMIT 1", :as => :array).each[0]
    p("REPLACE INTO wonders VALUES (#{week_number}, 'mlw', #{w[0]}, #{w[1]}, '#{w[2].round(2)} км')") if w[0]
    db.query("REPLACE INTO wonders VALUES (#{week_number}, 'mlw', #{w[0]}, #{w[1]}, '#{w[2].round(2)} км')") if w[0]
    # best girl in week mileage
    p("SELECT log.runnerid r, teamid t, COALESCE(SUM(distance),0) d FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=0 AND teamid>0 GROUP BY r ORDER BY d DESC LIMIT 1")
    w = db.query("SELECT log.runnerid r, teamid t, COALESCE(SUM(distance),0) d FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=0 AND teamid>0 GROUP BY r ORDER BY d DESC LIMIT 1", :as => :array).each[0]
    p("REPLACE INTO wonders VALUES (#{week_number}, 'flw', #{w[0]}, #{w[1]}, '#{w[2].round(2)} км')") if w[0]
    db.query("REPLACE INTO wonders VALUES (#{week_number}, 'flw', #{w[0]}, #{w[1]}, '#{w[2].round(2)} км')") if w[0]
    # best boy in week speed
    p("SELECT log.runnerid r, teamid t, COALESCE(SUM(time)/SUM(distance), 0) s FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=1 AND teamid>0 GROUP BY r ORDER BY s ASC LIMIT 1")
    w = db.query("SELECT log.runnerid r, teamid t, COALESCE(SUM(time)/SUM(distance), 0) s FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=1 AND teamid>0 GROUP BY r ORDER BY s ASC LIMIT 1", :as => :array).each[0]
    p("REPLACE INTO wonders VALUES (#{week_number}, 'mfw', #{w[0]}, #{w[1]}, CONCAT(TIME_FORMAT(SEC_TO_TIME(#{w[2].to_i}), '%i:%s'), ' мин/км'))") if w[0]
    db.query("REPLACE INTO wonders VALUES (#{week_number}, 'mfw', #{w[0]}, #{w[1]}, CONCAT(TIME_FORMAT(SEC_TO_TIME(#{w[2].to_i}), '%i:%s'), ' мин/км'))") if w[0]
    # best girl in week speed
    p("SELECT log.runnerid r, teamid t, COALESCE(SUM(time)/SUM(distance), 0) s FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=0 AND teamid>0 GROUP BY r ORDER BY s ASC LIMIT 1")
    w = db.query("SELECT log.runnerid r, teamid t, COALESCE(SUM(time)/SUM(distance), 0) s FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=0 AND teamid>0 GROUP BY r ORDER BY s ASC LIMIT 1", :as => :array).each[0]
    p("REPLACE INTO wonders VALUES (#{week_number}, 'ffw', #{w[0]}, #{w[1]}, CONCAT(TIME_FORMAT(SEC_TO_TIME(#{w[2].to_i}), '%i:%s'), ' мин/км'))") if w[0]
    db.query("REPLACE INTO wonders VALUES (#{week_number}, 'ffw', #{w[0]}, #{w[1]}, CONCAT(TIME_FORMAT(SEC_TO_TIME(#{w[2].to_i}), '%i:%s'), ' мин/км'))") if w[0]
    # best boy in run mileage
    p("SELECT log.runnerid, teamid, distance, runid FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=1 AND teamid>0 ORDER BY distance DESC LIMIT 1")
    w = db.query("SELECT log.runnerid, teamid, distance, runid FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=1 AND teamid>0 ORDER BY distance DESC LIMIT 1", :as => :array).each[0]
    p("REPLACE INTO wonders VALUES (#{week_number}, 'mlr', #{w[0]}, #{w[1]}, '<a href=\"http://strava.com/activities/#{w[3]}\">#{w[2].round(2)} км</a>')") if w[0]
    db.query("REPLACE INTO wonders VALUES (#{week_number}, 'mlr', #{w[0]}, #{w[1]}, '<a href=\"http://strava.com/activities/#{w[3]}\">#{w[2].round(2)} км</a>')") if w[0]
    # best girl in run mileage
    p("SELECT log.runnerid, teamid, distance, runid FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=0 AND teamid>0 ORDER BY distance DESC LIMIT 1")
    w = db.query("SELECT log.runnerid, teamid, distance, runid FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=0 AND teamid>0 ORDER BY distance DESC LIMIT 1", :as => :array).each[0]
    p("REPLACE INTO wonders VALUES (#{week_number}, 'flr', #{w[0]}, #{w[1]}, '<a href=\"http://strava.com/activities/#{w[3]}\">#{w[2].round(2)} км</a>')") if w[0]
    db.query("REPLACE INTO wonders VALUES (#{week_number}, 'flr', #{w[0]}, #{w[1]}, '<a href=\"http://strava.com/activities/#{w[3]}\">#{w[2].round(2)} км</a>')") if w[0]
    # best boy in run speed
    p("SELECT log.runnerid, teamid, time/distance sp, runid FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=1 AND time>0 AND distance>3.0 AND teamid>0 ORDER BY sp ASC LIMIT 1")
    w = db.query("SELECT log.runnerid, teamid, time/distance sp, runid FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=1 AND time>0 AND distance>3.0 AND teamid>0 ORDER BY sp ASC LIMIT 1", :as => :array).each[0]
    p("REPLACE INTO wonders VALUES (#{week_number}, 'mfr', #{w[0]}, #{w[1]}, CONCAT('<a href=\"http://strava.com/activities/#{w[3]}\">', TIME_FORMAT(SEC_TO_TIME(#{w[2].to_i}), '%i:%s'), ' мин/км</a>'))") if w[0]
    db.query("REPLACE INTO wonders VALUES (#{week_number}, 'mfr', #{w[0]}, #{w[1]}, CONCAT('<a href=\"http://strava.com/activities/#{w[3]}\">', TIME_FORMAT(SEC_TO_TIME(#{w[2].to_i}), '%i:%s'), ' мин/км</a>'))") if w[0]
    # best girl in run speed
    p("SELECT log.runnerid, teamid, time/distance sp, runid FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=0 AND time>0 AND distance>3.0 AND teamid>0 ORDER BY sp ASC LIMIT 1")
    w = db.query("SELECT log.runnerid, teamid, time/distance sp, runid FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=0 AND time>0 AND distance>3.0 AND teamid>0 ORDER BY sp ASC LIMIT 1", :as => :array).each[0]
    p("REPLACE INTO wonders VALUES (#{week_number}, 'ffr', #{w[0]}, #{w[1]}, CONCAT('<a href=\"http://strava.com/activities/#{w[3]}\">', TIME_FORMAT(SEC_TO_TIME(#{w[2].to_i}), '%i:%s'), ' мин/км</a>'))") if w[0]
    db.query("REPLACE INTO wonders VALUES (#{week_number}, 'ffr', #{w[0]}, #{w[1]}, CONCAT('<a href=\"http://strava.com/activities/#{w[3]}\">', TIME_FORMAT(SEC_TO_TIME(#{w[2].to_i}), '%i:%s'), ' мин/км</a>'))") if w[0]
    # best boy in percents
    p("SELECT r,t,100*d/g pct FROM (SELECT log.runnerid r, teamid t, goal*7/365 g, COALESCE(SUM(distance),0) d FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=1 AND teamid>0 GROUP BY r) rrs ORDER BY pct DESC LIMIT 1")
    w = db.query("SELECT r,t,100*d/g pct FROM (SELECT log.runnerid r, teamid t, goal*7/365 g, COALESCE(SUM(distance),0) d FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=1 AND teamid>0 GROUP BY r) rrs ORDER BY pct DESC LIMIT 1", :as => :array).each[0]
    p("REPLACE INTO wonders VALUES (#{week_number}, 'mmp', #{w[0]}, #{w[1]}, '#{w[2].round(2)}%')") if w[0]
    db.query("REPLACE INTO wonders VALUES (#{week_number}, 'mmp', #{w[0]}, #{w[1]}, '#{w[2].round(2)}%')") if w[0]
    # best girl in percents
    p("SELECT r,t,100*d/g pct FROM (SELECT log.runnerid r, teamid t, goal*7/365 g, COALESCE(SUM(distance),0) d FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=0 AND teamid>0 GROUP BY r) rrs ORDER BY pct DESC LIMIT 1")
    w = db.query("SELECT r,t,100*d/g pct FROM (SELECT log.runnerid r, teamid t, goal*7/365 g, COALESCE(SUM(distance),0) d FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow}' AND date<'#{eow}' AND sex=0 AND teamid>0 GROUP BY r) rrs ORDER BY pct DESC LIMIT 1", :as => :array).each[0]
    p("REPLACE INTO wonders VALUES (#{week_number}, 'fmp', #{w[0]}, #{w[1]}, '#{w[2].round(2)}%')") if w[0]
    db.query("REPLACE INTO wonders VALUES (#{week_number}, 'fmp', #{w[0]}, #{w[1]}, '#{w[2].round(2)}%')") if w[0]
end

def calcpoints (d)
    puts ">> calcpoints #{d}"
    if d.year != Time.now.year
        d = Time.new(2021, 1, 1)
        bow = d.to_s(:db)
    else
        bow = d.beginning_of_week.to_s(:db)
    end
    week_number = d.to_date.strftime('%W').to_i
    eow = d.end_of_week.to_s(:db)
    db = Mysql2::Client.new(:host => "localhost", :username => DBUSER, :password => DBPASSWD, :database => DB, :encoding => "utf8mb4")
    place = 0
    db.query("SELECT teamid, 100*distance/goal, distance, goal FROM teamwlog WHERE week=#{week_number} ORDER BY distance/goal", :as => :array).each do |t|
        wonders = db.query("SELECT count(*) FROM wonders WHERE teamid=#{t[0]} AND week=#{week_number}", :as => :array).each[0][0]
        points = place * 5 + wonders * 3
        place += 1
        p ("REPLACE INTO points VALUES (#{t[0]}, #{week_number}, #{points}, #{t[1]}, #{t[2]}, #{t[3]})")
        db.query("REPLACE INTO points VALUES (#{t[0]}, #{week_number}, #{points}, #{t[1]}, #{t[2]}, #{t[3]})")
    end
end
#def calcprolog ()
#    db = SQLite3::Database.new(DB)
#    teams = Array.new(TEAMS, 0)
#    runners = db.query("SELECT * FROM runners") 
#    runners.each do |r|
#        r << db.query("SELECT COALESCE(SUM(distance),0) AS d FROM log WHERE runnerid=#{r[0]} AND date>'#{STARTPROLOG.iso8601}' AND date<'#{ENDPROLOG.iso8601}' LIMIT 3")[0][0]
#    end
#    p runners
#    runners.sort! { |x,y| y[4] <=> x[4] }
#    p runners
#    teams[runners[0][2]] += 20
#    teams[runners[1][2]] += 10
#    teams[runners[2][2]] += 5
#    teams.each_with_index do |t, i|
#        db.query("INSERT OR REPLACE INTO points VALUES (#{i}, 1, #{t}, 0.0)")
#    end
#end

now = Time.now.getutc

if now < PROLOG.begin or now > (CHAMP.end + 2.days)
    puts "#{now}: Not yet time..."
    exit
end

if now >= PROLOG.begin and now <= (PROLOG.end + 2.days)
  if now.wday.between?(1, DOW-1) #and 1.week.ago.getutc.beginning_of_week >= PROLOG.begin
    calcwlog(1.week.ago)
    calcwonders(1.week.ago)
  end
  calcwlog(now)
  calcwonders(now)
end

if now >= CHAMP.begin and now <= (CHAMP.end + 2.days)
  if now.wday.between?(1, DOW-1) and 1.week.ago.getutc.beginning_of_week >= CHAMP.begin
    calcwlog(1.week.ago)
    calcwonders(1.week.ago)
    calcpoints(1.week.ago)
  end
  calcwlog(now)
  calcwonders(now)
  calcpoints(now)
end

