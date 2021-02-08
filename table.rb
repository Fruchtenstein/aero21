#!/usr/bin/ruby -W1
require 'mysql2'
require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './config.rb'

def printweek (w)
    output = ""
    db = Mysql2::Client.new(:host => "localhost", :username => DBUSER, :password => DBPASSWD, :database => DB, :encoding => "utf8mb4")
    teams = db.query("SELECT teams.teamid, points, pcts, teamname, bonus FROM points,teams WHERE points.teamid=teams.teamid AND week=#{w} ORDER BY points+bonus DESC", :as => :array).to_a
    output +=   "<center>\n"
    output +=   "    <br />\n"
    p "printweek: #{w}; #{Date.today.strftime('%W').to_i}; #{Date.today.wday}; #{DOW}\n"
    if w==Date.today.strftime('%W').to_i or (w==Date.today.strftime('%W').to_i-1 and Date.today.wday.between?(1, DOW-1))
        output +=   "    <h1>Предварительные результаты #{w} недели</h1>\n"
    else
        output +=   "    <h1>Результаты #{w} недели</h1>\n"
    end
    output +=   "    <!--a href=\"teams#{w}.html\">Подробнее</a-->\n"
    output +=   "    <br />\n"
    output +=   "</center>\n"
    output +=   "<div class=\"datagrid\"><table>\n"
    output +=   "   <thead><tr><th>Команда</th><th>Выполнено (%)</th><th>Очки</th><th>Бонусы</th><th>Очки+бонусы</th><th>Сумма</th></tr></thead>\n"
    output += "<tbody>\n\n"
    odd = true
    teams.each do |t|
        p t
        sum = db.query("SELECT SUM(points+bonus) FROM points WHERE teamid=#{t[0]} AND week<=#{w}", :as => :array).to_a[0]
        if odd
            output += "  <tr><td>#{t[3]}</td><td>#{t[2].round(2)}</td><td>#{t[1]}</td><td>#{t[4]}</td><td>#{t[1]+t[4]}</td><td>#{sum[0]}</td></tr>\n"
        else
            output += "  <tr class=\"alt\"><td>#{t[3]}</td><td>#{t[2].round(2)}</td><td>#{t[1]}</td><td>#{t[4]}</td><td>#{t[1]+t[4]}</td><td>#{sum[0]}</td></tr>\n"
        end
        odd = !odd
    end
    output +=   "   </tbody>\n"
    output +=   "</table>\n"
    output +=   "</div>\n"
    db.close
    return output
end


$stdout.sync = true
now = Time.now.getutc
dayno = now.yday
if now < PROLOG.begin or now > (CHAMP.end + 2.days)
    puts "#{now}: Not yet time..."
    exit
end

week = now.to_date.strftime('%W').to_i

prolog = ""
champ = ""
cup = ""


index_erb = ERB.new(File.read('index.html.erb'))
feed_erb = ERB.new(File.read('feed.html.erb'))
rules_erb = ERB.new(File.read('rules.html.erb'))
teams_erb = ERB.new(File.read('teams.html.erb'))
user_erb = ERB.new(File.read('u.html.erb'))
users_erb = ERB.new(File.read('users.html.erb'))
users2_erb = ERB.new(File.read('users2.html.erb'))
users3_erb = ERB.new(File.read('users3.html.erb'))
users4_erb = ERB.new(File.read('users4.html.erb'))
statistics_erb = ERB.new(File.read('statistics.html.erb'))

db = Mysql2::Client.new(:host => "localhost", :username => DBUSER, :password => DBPASSWD, :database => DB, :encoding => "utf8mb4")

### Process index.html
if now > PROLOG.begin #and now < 7.days.after(CLOSEPROLOG)
    prolog += "<center>\n"
    prolog += "<h1>Пролог</h1>\n"
    prolog += "</center>\n"
    prolog += "<div class=\"datagrid\">\n"
    prolog += "<table>\n"
    prolog += "<thead><tr><th>Имя</th><th>Команда</th><th>Объемы 2020 (км/нед)</th><th>Результат (км)</th></tr></thead>\n"
    prolog += "<tbody>\n"
    
    teams = db.query("SELECT * FROM teams", :as => :array).to_a
    
    runners = db.query("SELECT runnerid,runnername,7*goal/365,teamid FROM runners", :as => :array).to_a
    runners.each do |r|
        r << db.query("SELECT COALESCE(SUM(distance),0) AS dist FROM log WHERE runnerid=#{r[0]} AND date>'#{PROLOG.begin.to_s(:db)}' AND date<'#{PROLOG.end.to_s(:db)}'", :as => :array).to_a[0][0]
    end
    runners.sort! { |x,y| y[4] <=> x[4] }
    p runners
    odd = true
    runners.each do |r|
#        if now > CLOSEPROLOG
#            points = case runners.index(r)
#                     when 0 then 20
#                     when 1 then 10
#                     when 2 then 5
#                     else 0
#                     end
#        else
#            points = 0
#        end
        if odd then
            prolog += "<tr><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{teams[r[3]-1][1]}</td><td>#{r[2].round(2)}</td><td>#{r[4].round(2)}</td></tr>\n"
        else
            prolog += "<tr class=\"alt\"><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{teams[r[3]-1][1]}</td><td>#{r[2].round(2)}</td><td>#{r[4].round(2)}</td></tr>\n"
        end
        odd = !odd
    end
    
    prolog += "</tbody>\n"
    prolog += "</table></div>\n"
end

if now > CHAMP.begin
    w = Date.today.strftime('%W').to_i
    p w
    if Date.today.wday.between?(1, DOW-1)
        teams = db.query("SELECT teams.teamid, teamname, COALESCE(SUM(points),0) AS p, COALESCE(SUM(bonus),0) AS b FROM points, teams WHERE points.teamid=teams.teamid AND week<#{w-1} GROUP BY teams.teamid ORDER BY p+b DESC", :as => :array).to_a
    else
        teams = db.query("SELECT teams.teamid, teamname, COALESCE(SUM(points),0) AS p, COALESCE(SUM(bonus),0) AS b FROM points, teams WHERE points.teamid=teams.teamid AND week<#{w} GROUP BY teams.teamid ORDER BY p+b DESC", :as => :array).to_a
    end
    champ +=   "<center>\n"
    champ +=   "    <br />\n"
    champ +=   "    <h1>Текущее положение команд</h1>\n"
    champ +=   "    <br />\n"
    champ +=   "</center>\n"
    champ +=   "<div class=\"datagrid\"><table>\n"
    champ +=   "   <thead><tr><th>Команда</th><th>Очки</th></tr></thead>\n"
    champ +=   "    <tbody>\n"
    odd = true
    teams.each do |t|
        if odd
            champ += "  <tr><td>#{t[1]}</td><td>#{t[2]+t[3]}</td></tr>\n"
        else
            champ += "  <tr class=\"alt\"><td>#{t[1]}</td><td>#{t[2]+t[3]}</td></tr>\n"
        end
        odd = !odd
    end
    champ +=   "   </tbody>\n"
    champ +=   "</table>\n"
    champ +=   "</div>\n"
    champ +=   "<br />\n"
    champ += printweek w
    champ +=   "<br />\n"
    [*CHAMP.begin.to_date.strftime('%W').to_i..(Date.today.strftime('%W').to_i-1)].reverse_each do |w|
         p w
         champ += printweek w
    end
end

if now > CUP.begin
  w = Date.today.strftime('%W').to_i
  start_cup_week = CUP.begin.to_date.strftime('%W').to_i
  final_week = start_cup_week + 8
  half_week = start_cup_week + 4
  cup_week = w - start_cup_week + 1
  (1..(TEAMS-1)).each do |i|
    cup += "<center>\n"
    cup += "  <br />\n"
    if i == 7
      cup += "  <h1>Финал</h1>"
      calc_week = final_week
    elsif i.between?(5, 6)
      cup += "  <h1>Полуфинал #{i-4}</h1>"
      calc_week = half_week
    else
      cup += "  <h1>Четвертьфинал #{i}</h1>"
      calc_week = start_cup_week
    end
    cup += "</center>\n"
    cup += "<div class=\"datagrid\"><table>\n"
    cup += "  <thead><tr><th>Неделя</th><th>Команда</th><th>Результат (км)</th></tr></thead>\n"
    cup += "  <tbody>\n"
    teams = db.query("SELECT teamid FROM playoff WHERE bracket=#{i}", :as => :array).to_a
    if teams[0][0] == 0 and teams[1][0] == 0
      t1 = '?'
      t2 = '?'
    else
      t1 = db.query("SELECT teamname FROM teams WHERE teamid=#{teams[0][0]}", :as => :array).to_a[0][0]
      t2 = db.query("SELECT teamname FROM teams WHERE teamid=#{teams[1][0]}", :as => :array).to_a[0][0]
    end
    (0..2).each do |n|
      d1 = (db.query("SELECT COALESCE(distance,0) FROM teamwlog WHERE teamid=#{teams[0][0]} AND week=#{calc_week+n}", :as => :array).to_a[0] || [0.0])[0]
      d2 = (db.query("SELECT COALESCE(distance,0) FROM teamwlog WHERE teamid=#{teams[1][0]} AND week=#{calc_week+n}", :as => :array).to_a[0] || [0.0])[0]
      if n == 1
        cup += "    <tr class=\"alt\"><td rowspan=\"2\">#{n+1}</td><td>#{t1}</td><td>#{d1.round(2)}</td></tr>\n"
        cup += "    <tr class=\"alt\"><td>#{t2}</td><td>#{d2.round(2)}</td></tr>\n"
      else
        cup += "    <tr><td rowspan=\"2\">#{n+1}</td><td>#{t1}</td><td>#{d1.round(2)}</td></tr>\n"
        cup += "    <tr><td>#{t2}</td><td>#{d2.round(2)}</td></tr>\n"
      end
    end
    cup += "  </tbody>\n"
    cup += "</table>\n"
    cup += "</div>\n"
  end
  cup += "<hr />\n"
end



File.open('html/index.html', 'w') { |f| f.write(index_erb.result) }
File.open('html/rules.html', 'w') { |f| f.write(rules_erb.result) }

### Process users' personal pages
data = ""
runners = db.query("SELECT * FROM runners ORDER BY runnername", :as => :array).to_a
teams = db.query("SELECT * FROM teams", :as => :array).to_a
runners.each do |r|
    note = db.query("SELECT title FROM titles WHERE runnerid=#{r[0]}", :as => :array).to_a.join("<br />")
    data = ""
    data += "<center>\n"
    data += "<h1>Карточка участника</h1>\n"
    data += "</center>\n"
    data += "<div class=\"datagrid\">\n"
    data += "<table>\n"
    data += "<tbody>\n"
    data += "<tr><td><b>Имя</b></td><td>#{r[1]}</td></tr>"
    data += "<tr><td><b>Команда</b></td><td>#{r[2]==0 ? "-" : teams[r[4]-1][1]}</td></tr>"
    data += "<tr><td><b>Недельный план</b></td><td>#{(7*r[5]/365).round(2)}</td></tr>"
    data += "<tr><td><b>Достижения</b></td><td>#{note}</td></tr>"
    data += "<tr><td><b>Профиль на Страве</b></td><td><a href=\"https://strava.com/athletes/#{r[0]}\">https://strava.com/athletes/#{r[0]}</a></td></tr>"
    data += "</tbody>\n"
    data += "</table>\n"

    odd = true
    data2 = ''
    data2 += "<div class=\"datagrid\"><table>\n"
    data2 += "  <thead><tr><th>Неделя</th><th>Результат (км)</th><th>Общее время</th><th>Средний темп</th></tr></thead>\n"
    data2 += "  <tbody>\n"
    db.query("SELECT runnerid, week, distance, DATE_FORMAT(SEC_TO_TIME(ROUND(time,0)), '%H:%i:%s'), DATE_FORMAT(SEC_TO_TIME(ROUND(time/distance, 0)), '%i:%s') FROM wlog WHERE runnerid=#{r[0]}", :as => :array).each do |wr|
      puts "~~~~~~~~~~~~~~~~~~ #{wr[3].class} #{wr[3]}"
      if odd then
        odd = false
        data2 += "  <tr><td>#{wr[1]}</td><td>#{wr[2].round(2)}</td><td>#{wr[3]}</td><td>#{wr[4]}</td></tr>\n"
      else
        odd = true
        data2 += "  <tr class='alt'><td>#{wr[1]}</td><td>#{wr[2].round(2)}</td><td>#{wr[3]}</td><td>#{wr[4]}</td></tr>\n"
      end
    end
    data2 += "  </tbody>\n"
    data2 += "</table>\n"

    File.open("html/u#{r[0]}.html", 'w') { |f| f.write(user_erb.result(binding)) }
end

### Process users.html
data = ""
data += "<center>\n"
data += "<h1>По километрам</h1>\n"
data += "</center>\n"
data += "<div class=\"datagrid\">\n"
data += "<table>\n"
data += "<tbody>\n"
data += "<thead><tr><th></th><th>Имя</th><th>Объемы 2021 (км)</th><th>Объемы 2021 (%)</th><th>Объемы 2020 (км)</th><th>Команда</th></tr></thead>\n"
odd = true
i = 0
db.query("SELECT runnerid, runnername, teamname, (SELECT COALESCE(SUM(distance),0) FROM log WHERE runnerid=r.runnerid) d, (SELECT goal FROM runners WHERE runnerid=r.runnerid) g, 100*(SELECT COALESCE(SUM(distance),0) FROM log WHERE runnerid=r.runnerid)/(SELECT goal FROM runners WHERE runnerid=r.runnerid) FROM runners r JOIN teams USING (teamid) ORDER BY d DESC", :as => :array).each do |r|
  note = db.query("SELECT title FROM titles WHERE runnerid=#{r[0]}", :as => :array).to_a.join("<br />")
  if odd
    if r[3]>dayno*r[4]/365
      data += "<tr><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\"><b>#{r[1]}</b></a></td><td>#{r[3].round(2)}</td><td>#{r[5].round(2)}</td><td>#{r[4].round(2)}</td><td>#{r[2]}</td></tr>\n"
    else
      data += "<tr><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{r[3].round(2)}</td><td>#{r[5].round(2)}</td><td>#{r[4].round(2)}</td><td>#{r[2]}</td></tr>\n"
    end
  else
    if r[3]>dayno*r[4]/365
      data += "<tr class=\"alt\"><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\"><b>#{r[1]}</b></a></td><td>#{r[3].round(2)}</td><td>#{r[5].round(2)}</td><td>#{r[4].round(2)}</td><td>#{r[2]}</td></tr>\n"
    else
      data += "<tr class=\"alt\"><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{r[3].round(2)}</td><td>#{r[5].round(2)}</td><td>#{r[4].round(2)}</td><td>#{r[2]}</td></tr>\n"
    end
  end
  odd = !odd
end
data += "</tbody>\n"
data += "</table>\n"
data += "</div>\n"
data += "<br />\n"
File.open("html/users.html", 'w') { |f| f.write(users_erb.result(binding)) }

### Process users2.html
data = ""
data += "<center>\n"
data += "<h1>По процентам</h1>\n"
data += "</center>\n"
data += "<div class=\"datagrid\">\n"
data += "<table>\n"
data += "<tbody>\n"
data += "<thead><tr><th></th><th>Имя</th><th>Объемы 2021 (%)</th><th>Объемы 2021 (км)</th><th>Объемы 2020 (км)</th><th>Команда</th></tr></thead>\n"
odd = true
i = 0
db.query("SELECT runnerid, runnername, teamname, (SELECT COALESCE(SUM(distance),0) FROM log WHERE runnerid=r.runnerid) d, (SELECT goal FROM runners WHERE runnerid=r.runnerid) g, 100*(SELECT COALESCE(SUM(distance),0) FROM log WHERE runnerid=r.runnerid)/(SELECT goal FROM runners WHERE runnerid=r.runnerid) p FROM runners r JOIN teams USING (teamid) ORDER BY p DESC", :as => :array).each do |r|
  note = db.query("SELECT title FROM titles WHERE runnerid=#{r[0]}", :as => :array).to_a.join("<br />")
  if odd
    if r[3]>dayno*r[4]/365
      data += "<tr><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\"><b>#{r[1]}</b></a></td><td>#{r[5].round(2)}</td><td>#{r[3].round(2)}</td><td>#{r[4].round(2)}</td><td>#{r[2]}</td></tr>\n"
    else
      data += "<tr><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{r[5].round(2)}</td><td>#{r[3].round(2)}</td><td>#{r[4].round(2)}</td><td>#{r[2]}</td></tr>\n"
    end
  else
    if r[3]>dayno*r[4]/365
      data += "<tr class=\"alt\"><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\"><b>#{r[1]}</b></a></td><td>#{r[5].round(2)}</td><td>#{r[3].round(2)}</td><td>#{r[4].round(2)}</td><td>#{r[2]}</td></tr>\n"
    else
      data += "<tr class=\"alt\"><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{r[5].round(2)}</td><td>#{r[3].round(2)}</td><td>#{r[4].round(2)}</td><td>#{r[2]}</td></tr>\n"
    end
  end
  odd = !odd
end
data += "</tbody>\n"
data += "</table>\n"
data += "</div>\n"
data += "<br />\n"
File.open("html/users2.html", 'w') { |f| f.write(users2_erb.result(binding)) }

### Process users3.html
data = ""
data += "<center>\n"
data += "<h1>По результатам 2020 года</h1>\n"
data += "</center>\n"
data += "<div class=\"datagrid\">\n"
data += "<table>\n"
data += "<tbody>\n"
data += "<thead><tr><th></th><th>Имя</th><th>Объемы 2020 (км)</th><th>Объемы 2021 (км)</th><th>Объемы 2021 (%)</th><th>Команда</th></tr></thead>\n"
odd = true
i = 0
db.query("SELECT runnerid, runnername, teamname, (SELECT COALESCE(SUM(distance),0) FROM log WHERE runnerid=r.runnerid) d, (SELECT goal FROM runners WHERE runnerid=r.runnerid) g, 100*(SELECT COALESCE(SUM(distance),0) FROM log WHERE runnerid=r.runnerid)/(SELECT goal FROM runners WHERE runnerid=r.runnerid) p FROM runners r JOIN teams USING (teamid) ORDER BY g DESC", :as => :array).each do |r|
  note = db.query("SELECT title FROM titles WHERE runnerid=#{r[0]}", :as => :array).to_a.join("<br />")
  if odd
    if r[3]>dayno*r[4]/365
      data += "<tr><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\"><b>#{r[1]}</b></a></td><td>#{r[4].round(2)}</td><td>#{r[3].round(2)}</td><td>#{r[5].round(2)}</td><td>#{r[2]}</td></tr>\n"
    else
      data += "<tr><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{r[4].round(2)}</td><td>#{r[3].round(2)}</td><td>#{r[5].round(2)}</td><td>#{r[2]}</td></tr>\n"
    end
  else
    if r[3]>dayno*r[4]/365
      data += "<tr class=\"alt\"><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\"><b>#{r[1]}</b></a></td><td>#{r[4].round(2)}</td><td>#{r[3].round(2)}</td><td>#{r[5].round(2)}</td><td>#{r[2]}</td></tr>\n"
    else
      data += "<tr class=\"alt\"><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{r[4].round(2)}</td><td>#{r[3].round(2)}</td><td>#{r[5].round(2)}</td><td>#{r[2]}</td></tr>\n"
    end
  end
  odd = !odd
end
data += "</tbody>\n"
data += "</table>\n"
data += "</div>\n"
data += "<br />\n"
File.open("html/users3.html", 'w') { |f| f.write(users3_erb.result(binding)) }

### Process users4.html
data = ""
data += "<center>\n"
data += "<h1>Команды и участники</h1>\n"
data += "</center>\n"
db.query("SELECT * FROM teams ORDER BY teamid", :as => :array).each do |t|
    data += "<center>\n"
    data += "<h2>#{t[1]}</h2>\n"
    data += "</center>\n"
    data += "<div class=\"datagrid\">\n"
    data += "<table>\n"
    data += "<tbody>\n"
    data += "<thead><tr><th></th><th>Имя</th><th>Объемы 2020 (км/год)</th><th>Примечания</th></tr></thead>\n"
    odd = true
    i = 0
    db.query("SELECT * FROM runners WHERE teamid=#{t[0]} ORDER BY goal DESC", :as => :array).each do |r|
        note = db.query("SELECT title FROM titles WHERE runnerid=#{r[0]}", :as => :array).to_a.join("<br />")
        dist = db.query("SELECT SUM(distance) FROM wlog WHERE runnerid=#{r[0]}", :as => :array).to_a[0][0]
        if odd
          if dist>dayno*r[5]/365
            data += "<tr><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\"><b>#{r[1]}</b></a></td><td>#{r[5].round(2)}</td><td>#{note}</td></tr>\n"
          else
            data += "<tr><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{r[5].round(2)}</td><td>#{note}</td></tr>\n"
          end
        else
          if dist>dayno*r[5]/365
            data += "<tr class=\"alt\"><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\"><b>#{r[1]}</b></a></td><td>#{r[5].round(2)}</td><td>#{note}</td></tr>\n"
          else
            data += "<tr class=\"alt\"><td>#{i+=1}</td><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{r[5].round(2)}</td><td>#{note}</td></tr>\n"
          end
        end
        odd = !odd
    end
    data += "</tbody>\n"
    data += "</table>\n"
    data += "</div>\n"
    data += "<br />\n"
end
File.open("html/users4.html", 'w') { |f| f.write(users4_erb.result(binding)) }

### Process teams*.html
if now > PROLOG.begin
[*PROLOG.begin.to_date.strftime('%W').to_i..(Date.today.strftime('%W').to_i)].reverse_each do |w|
     puts "teams#{w}...."
     p w
     if w == 0
         bow = PROLOG.begin
         eow = PROLOG.begin.end_of_week
     else
         bow = DateTime.parse(Date.commercial(2021,w).to_s).beginning_of_week
         eow = DateTime.parse(Date.commercial(2021,w).to_s).end_of_week
     end
     p bow.to_s(:db), eow.to_s(:db)
     teams = db.query("SELECT * FROM teams", :as => :array).to_a
     data = ""
     db.query("SELECT * FROM teams", :as => :array).each do |t|
         p t
         data +=   "<center>\n"
         data +=   "    <br />\n"
         data +=   "    <br />\n"
         data +=   "    <h1>#{t[1]}</h1>\n"
         data +=   "</center>\n"
         data +=   "<div class=\"datagrid\"><table>\n"
         data +=   "   <thead><tr><th>Имя</th><th>Цель (км/нед)</th><th>Результат (км)</th><th>Выполнено (%)</th></tr></thead>\n"
         data +=   "    <tbody>\n"
         sum_dist = 0
         sum_pct = 0
         sum_goal = 0
         odd = true
         runners = db.query("SELECT * FROM runners WHERE teamid=#{t[0]} ORDER BY goal DESC", :as => :array).to_a
         runners.each do |r|
             dist = db.query("SELECT COALESCE(SUM(distance),0) FROM log WHERE runnerid=#{r[0]} AND date>'#{bow.to_s(:db)}' AND date<'#{eow.to_s(:db)}'", :as => :array).to_a[0][0]
             goal = 7*r[5]/365
             pct = (dist/goal)*100
             sum_dist += dist
             sum_pct += pct
             sum_goal += goal
             if odd
                 data += "  <tr><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{goal.round(2)}</td><td><a href=\"https://strava.com/athletes/#{r[0]}#interval?interval=#{CHAMP.begin.year.to_s+w.to_s.rjust(2,"0")}&interval_type=week&chart_type=miles&year_offset=0\">#{dist.round(2)}</a></td><td>#{pct.round(2)}</td></tr>\n"
             else
                 data += "  <tr class=\"alt\"><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{goal.round(2)}</td><td><a href=\"http://strava.com/athletes/#{r[0]}#interval?interval=#{CHAMP.begin.year.to_s+w.to_s.rjust(2,"0")}&interval_type=week&chart_type=miles&year_offset=0\">#{dist.round(2)}</a></td><td>#{pct.round(2)}</td></tr>\n"
             end
             odd = !odd
         end
         data +=  "<tfoot><tr><td>Всего:</td><td>#{sum_goal.round(2)}</td><td>#{sum_dist.round(2)}</td><td>#{(100*sum_dist/sum_goal).round(2)}</td></tr></tfoot>\n"
         data +=   "   </tbody>\n"
         data +=   "</table>\n"
         data +=   "</div>\n"
     end
     box  = "<nav class=\"sub\">\n"
     box += "      <ul>\n"
     (PROLOG.begin.to_date.strftime('%W').to_i..Date.today.strftime('%W').to_i).each do |wk|
         if wk == w
             box += "        <li class=\"active\"><span>#{wk} неделя</span></li>\n"
         else
             box += "        <li><a href=\"teams#{wk}.html\">#{wk} неделя</a></li>\n"
         end
     end
     box += "      </ul>\n"
     box += "    </nav>\n"
     File.open("html/teams#{w}.html", 'w') { |f| f.write(teams_erb.result(binding)) }
end
end
### Process statistics*.html
#if Date.today > CHAMP.begin
[*PROLOG.begin.to_date.strftime('%W').to_i..(Date.today.strftime('%W').to_i)].reverse_each do |w|
begin
puts "statistics#{w}...."
     p w
     if w == 0
         bow = PROLOG.begin
         eow = PROLOG.begin.end_of_week
     else
         bow = DateTime.parse(Date.commercial(2021,w).to_s).beginning_of_week
         eow = DateTime.parse(Date.commercial(2021,w).to_s).end_of_week
     end
     p bow.to_s(:db), eow.to_s(:db)
     data = ""
     data +=   "<center>\n"
     data +=   "    <br />\n"
     data +=   "    <br />\n"
     data +=   "    <h1>Чудеса недели</h1>\n"
     data +=   "</center>\n"
     data +=   "<div class=\"datagrid\"><table>\n"
     data +=   "   <thead><tr><th></th><th>Имя</th><th>Команда</th><th>Результат (км)</th></tr></thead>\n"
     data +=   "    <tbody>\n"

     x = db.query("SELECT wonders.runnerid, runnername, wonder, teamname FROM wonders, runners, teams WHERE wonders.runnerid=runners.runnerid AND wonders.teamid=teams.teamid AND week=#{w} AND type='mlw'", :as => :array).to_a[0] || [0,'',0,'']
     data +=   "    <tr><td>Больше всех километров среди мужчин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2]}</td></tr>\n"

     x = db.query("SELECT wonders.runnerid, runnername, wonder, teamname FROM wonders, runners, teams WHERE wonders.runnerid=runners.runnerid AND wonders.teamid=teams.teamid AND week=#{w} AND type='flw'", :as => :array).to_a[0] || [0,'',0,'']
     data +=   "    <tr class='alt'><td>Больше всех километров среди женщин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2]}</td></tr>\n"

     x = db.query("SELECT wonders.runnerid, runnername, wonder, teamname FROM wonders, runners, teams WHERE wonders.runnerid=runners.runnerid AND wonders.teamid=teams.teamid AND week=#{w} AND type='mlr'", :as => :array).to_a[0] || [0,'',0,'']
     data +=   "    <tr><td>Самая длинная тренировка у мужчин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2]}</td></tr>\n"

     x = db.query("SELECT wonders.runnerid, runnername, wonder, teamname FROM wonders, runners, teams WHERE wonders.runnerid=runners.runnerid AND wonders.teamid=teams.teamid AND week=#{w} AND type='flr'", :as => :array).to_a[0] || [0,'',0,'']
     data +=   "    <tr class='alt'><td>Самая длинная тренировка у женщин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2]}</td></tr>\n"

     x = db.query("SELECT wonders.runnerid, runnername, wonder, teamname FROM wonders, runners, teams WHERE wonders.runnerid=runners.runnerid AND wonders.teamid=teams.teamid AND week=#{w} AND type='mfr'", :as => :array).to_a[0] || [0,'',0,'']
     data +=   "    <tr><td>Самая быстрая тренировка у мужчин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2]}</td></tr>\n"

     x = db.query("SELECT wonders.runnerid, runnername, wonder, teamname FROM wonders, runners, teams WHERE wonders.runnerid=runners.runnerid AND wonders.teamid=teams.teamid AND week=#{w} AND type='ffr'", :as => :array).to_a[0] || [0,'',0,'']
     data +=   "    <tr class='alt'><td>Самая быстрая тренировка у женщин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2]}</td></tr>\n"

     x = db.query("SELECT wonders.runnerid, runnername, wonder, teamname FROM wonders, runners, teams WHERE wonders.runnerid=runners.runnerid AND wonders.teamid=teams.teamid AND week=#{w} AND type='mfw'", :as => :array).to_a[0] || [0,'',0,'']
     data +=   "    <tr><td>Самый быстрый средний темп у мужчин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2]}</td></tr>\n"

     x = db.query("SELECT wonders.runnerid, runnername, wonder, teamname FROM wonders, runners, teams WHERE wonders.runnerid=runners.runnerid AND wonders.teamid=teams.teamid AND week=#{w} AND type='ffw'", :as => :array).to_a[0] || [0,'',0,'']
     data +=   "    <tr class='alt'><td>Самый быстрый средний темп у женщин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2]}</td></tr>\n"

     x = db.query("SELECT l.runnerid, runnername, d, teamname FROM \
                        (SELECT runnerid, 100*SUM(distance)/(SELECT 7*goal/365 FROM runners WHERE runnerid=log.runnerid) d \
                                FROM log WHERE date>'#{bow.to_s(:db)}' AND date<'#{eow.to_s(:db)}' GROUP BY runnerid) l, runners, teams \
                                    WHERE runners.runnerid=l.runnerid AND sex=1 AND teams.teamid=runners.teamid ORDER BY d DESC LIMIT 1", :as => :array).to_a[0] || [0,'',0,'']
     p x
     x[0] = x[0] || 0
     x[1] = x[1] || ''
     x[2] = x[2] || 0
     x[3] = x[3] || ''
     data +=   "    <tr><td>Больше всех процентов среди мужчин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2].round(2)}%</td></tr>\n"

     x = db.query("SELECT l.runnerid, runnername, d, teamname FROM \
                        (SELECT runnerid, 100*SUM(distance)/(SELECT 7*goal/365 FROM runners WHERE runnerid=log.runnerid) d \
                                FROM log WHERE date>'#{bow.to_s(:db)}' AND date<'#{eow.to_s(:db)}' GROUP BY runnerid) l, runners, teams \
                                    WHERE runners.runnerid=l.runnerid AND sex=0 AND teams.teamid=runners.teamid ORDER BY d DESC LIMIT 1", :as => :array).to_a[0] || [0,'',0,'']
     p x
     x[0] = x[0] || 0
     x[1] = x[1] || ''
     x[2] = x[2] || 0
     x[3] = x[3] || ''
     data +=   "    <tr class='alt'><td>Больше всех процентов среди женщин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2].round(2)}%</td></tr>\n"


     x = db.query(" SELECT teamname, DATE_FORMAT(SEC_TO_TIME(ROUND(time/distance, 0)), '%i:%s') FROM teamwlog l, teams t WHERE l.teamid=t.teamid AND week=#{w}", :as => :array).to_a[0] 
     p(" SELECT teamname, DATE_FORMAT(SEC_TO_TIME(ROUND(time/distance, 0)), '%i:%s') FROM teamwlog l, teams t WHERE l.teamid=t.teamid AND week=#{w}")
     data += "    <tr><td>Самая быстрая команда</td><td></td><td>#{x[0]}</td><td>#{x[1]}</td></tr>\n"

     data +=   "   </tbody>\n"
     data +=   "</table>\n"
     data +=   "</div>\n"
     data +=   "<br />\n"
     data +=   "<center>\n"
     data +=   "    <br />\n"
     data +=   "    <br />\n"
     data +=   "    <h1>Раздача слонов за год</h1>\n"
     data +=   "    <h2>командам</h2>\n"
     data +=   "</center>\n"
     data +=   "<div class=\"datagrid\"><table>\n"
     data +=   "   <thead><tr><th>Команда</th><th>Очки</th></tr></thead>\n"
     data +=   "    <tbody>\n"
     x = db.query("SELECT COALESCE(teamname, ''), count(*) c FROM wonders w LEFT JOIN teams t ON w.teamid=t.teamid WHERE w.week<=#{w} GROUP BY w.teamid ORDER BY c DESC", :as => :array).to_a
     odd = false
     x.each do |r|
       if odd
         data += "  <tr><td>#{r[0]}</td><td>#{r[1]*3}</td></tr>\n"
       else
         data += "  <tr class=\"alt\"><td>#{r[0]}</td><td>#{r[1]*3}</td></tr>\n"
       end
       odd = !odd
     end
     data +=   "   </tbody>\n"
     data +=   "</table>\n"
     data +=   "</div>\n"
     data +=   "<center>\n"
     data +=   "    <br />\n"
     data +=   "    <br />\n"
     data +=   "    <h2>и участникам</h2>\n"
     data +=   "</center>\n"
     data +=   "<div class=\"datagrid\"><table>\n"
     data +=   "   <thead><tr><th>Имя</th><th>Команда</th><th>Очки</th></tr></thead>\n"
     data +=   "    <tbody>\n"
     x = db.query("SELECT runnername, COALESCE(teamname, ''), count(*) c FROM runners r, wonders w LEFT JOIN teams t ON w.teamid=t.teamid WHERE w.runnerid=r.runnerid AND w.week<=#{w} GROUP BY w.runnerid ORDER BY c DESC", :as => :array).to_a
     odd = false
     x.each do |r|
       if odd
         data += "  <tr><td>#{r[0]}</td><td>#{r[1]}</td><td>#{r[2]*3}</td></tr>\n"
       else
         data += "  <tr class=\"alt\"><td>#{r[0]}</td><td>#{r[1]}</td><td>#{r[2]*3}</td></tr>\n"
       end
       odd = !odd
     end
     data +=   "   </tbody>\n"
     data +=   "</table>\n"
     data +=   "</div>\n"
     data +=   "<br />\n"

     box  = "<nav class=\"sub\">\n"
     box += "      <ul>\n"
     (PROLOG.begin.to_date.strftime('%W').to_i..Date.today.strftime('%W').to_i).each do |wk|
         if wk == w
             box += "        <li class=\"active\"><span>#{wk} неделя</span></li>\n"
         else
             box += "        <li><a href=\"statistics#{wk}.html\">#{wk} неделя</a></li>\n"
         end
     end
     box += "      </ul>\n"
     box += "    </nav>\n"
     File.open("html/statistics#{w}.html", 'w') { |f| f.write(statistics_erb.result(binding)) }
end
end
#end
### Process feed*.html
[*PROLOG.begin.to_date.strftime('%W').to_i..(Date.today.strftime('%W').to_i)].reverse_each do |w|
     puts "feed#{w}...."
     if w == 0
         bow = PROLOG.begin
         eow = PROLOG.begin.end_of_week
     else
         bow = DateTime.parse(Date.commercial(2021,w).to_s).beginning_of_week
         eow = DateTime.parse(Date.commercial(2021,w).to_s).end_of_week
     end
     p bow.to_s(:db), eow.to_s(:db)
     data = ""
#     data +=   "<center>\n"
#     data +=   "    <br />\n"
#     data +=   "    <br />\n"
#     data +=   "    <h1>Тренировки недели</h1>\n"
#     data +=   "</center>\n"
     data +=   "<div class=\"datagrid\"><table>\n"
     data +=   "   <thead><tr><th>Тренировки недели</th><th></th></tr></thead>\n"
     data +=   "    <tbody>\n"
     odd = true
     p("SELECT date, runnername, distance, time, DATE_FORMAT(SEC_TO_TIME(ROUND(time/distance, 0)), '%i:%s'), \
                name, start_date_local, timezone, location_city, location_state, location_country, runid \
     FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow.to_s(:db)}' \
                       AND date<'#{eow.to_s(:db)}' ORDER BY date DESC")
     db.query("SELECT date, runnername, distance, time, DATE_FORMAT(SEC_TO_TIME(ROUND(time/distance, 0)), '%i:%s'), \
                name, start_date_local, timezone, location_city, location_state, location_country, runid \
     FROM log, runners WHERE log.runnerid=runners.runnerid AND date>'#{bow.to_s(:db)}' \
                       AND date<'#{eow.to_s(:db)}' ORDER BY date DESC", :as => :array).each do |t|
       dist = t[2].round(2)
       d = t[0].to_datetime
       dd = "#{d.day}.#{d.month.to_s.rjust(2,"0")}.#{d.year}, #{d.hour}:#{d.min.to_s.rjust(2,"0")}:#{d.sec.to_s.rjust(2,"0")}"
       t[6] = t[6] || t[0]  # set local time to UTC if local time is not available
       ld = t[6].to_datetime
       ldd = "#{ld.day}.#{ld.month.to_s.rjust(2,"0")}.#{ld.year}, #{ld.hour}:#{ld.min.to_s.rjust(2,"0")}:#{ld.sec.to_s.rjust(2,"0")}"
       hh = t[3] / 3600
       mm = (t[3] / 60 % 60).to_s.rjust(2,"0")
       ss = (t[3] % 60).to_s.rjust(2,"0")
       title = t[5] || ''
       lcity = t[8] || ''
       lstate = t[9] || ''
       lcountry = t[10] || ''
       place = "#{lcity} #{lstate} #{lcountry}"
#       data += "     <tr><td>#{t[0]}</td><td>#{t[1]}</td><td>#{t[2]}</td><td>#{t[3]}</td><td>#{t[4]}</td>\n"
       if odd then
#         odd = false
         data += "     <tr><td>\n"
       else
         odd = true
         data += "     <tr class='alt'><td>\n"
       end

#       data += "      <table border='0'><tr><td width='20%'>#{dd}</td><td width='30%'><b>#{t[1]}</b></td><td>Дистанция:<b>#{t[2].round(2)} км.</b></td><td>Время:<b> #{hh}:#{mm}:#{ss}</b></td><td>Темп:<b>#{t[4]}</b></td></tr></table>\n"
#       data += "      <table border='0'><tr><td>#{t[5]}</td></tr></table>\n"
#       data += "      <table border='0'><tr><td>#{t[8]} #{t[9]} #{t[10]}</td></tr></table>\n"
       data += "       <hr />\n"
       data += "       <table style='border:0px white'><tr><td width='30%'><h4>#{t[1]}</h4></td><td><a href='https://strava.com/activities/#{t[11]}'><h4>#{title}</h4></a></td></tr></table>" 
       data += "        <table border='0'><tr><td width='30%'><b>Дата:</b></td><td width='30%'><b>Дистанция:</b></td><td><b>Время:</b></td></tr>\n"
       data += "        <tr><td width='30%'>#{dd}</td><td>#{t[2].round(2)} км.</td><td>#{hh}:#{mm}:#{ss}</td></tr></table>\n"
       data += "        <table border='0'><tr><td width='30%'><b>Местное время:</b></td><td width='30%'><b>Место:</b></td><td><b>Темп:</b></td></tr>\n"
       data += "        <tr><td width='30%'>#{ldd}</td><td>#{place}</td><td>#{t[4]}</td></tr></table>\n"
       data += "     </td>\n"
       data += "     <td>\n"
       data += "        <hr />\n"
       data += "        <img src='maps/m#{t[11]}.png' />\n"
       data += "     </td>\n"
       data += "     </tr>\n"
     end

     data +=   "   </tbody>\n"
     data +=   "</table>\n"
     data +=   "</div>\n"
     data +=   "<br />\n"

     box  = "<nav class=\"sub\">\n"
     box += "      <ul>\n"
     (PROLOG.begin.to_date.strftime('%W').to_i..Date.today.strftime('%W').to_i).each do |wk|
         if wk == w
             box += "        <li class=\"active\"><span>#{wk} неделя</span></li>\n"
         else
             box += "        <li><a href=\"feed#{wk}.html\">#{wk} неделя</a></li>\n"
         end
     end
     box += "      </ul>\n"
     box += "    </nav>\n"
     File.open("html/feed#{w}.html", 'w') { |f| f.write(feed_erb.result(binding)) }
end

