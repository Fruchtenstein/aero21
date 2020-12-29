#!/usr/bin/python, paces3

import sqlite3
import datetime
import pytz
import os
from string import Template
#import config
import numpy as np
import sqlite3
import matplotlib.pyplot as plt
from matplotlib.ticker import MultipleLocator
from matplotlib.lines import Line2D

def sec2min(sec):
    return "{}:{:02d}".format(int(sec//60),int(sec%60))


now = datetime.date.today()
week = int(now.strftime("%W")) + 1
prevweek = week - 1
dolastweek = now.weekday() < 2
db = sqlite3.connect('2020.db')
c1 = db.cursor()

fig, ax = plt.subplots()


weeks = [x[0] for x in c1.execute('SELECT DISTINCT week FROM points ORDER BY week').fetchall()]
teams = c1.execute('SELECT teamid, teamname FROM teams').fetchall()
fig, ax = plt.subplots()
for t in teams:
    team = t[1]
    a = [x[0] for x in c1.execute('SELECT points FROM points WHERE teamid=? ORDER BY week', (t[0],))]
    print(weeks)
    print(a)
    ax.plot(weeks, np.cumsum(a), label=team)
handles, labels = ax.get_legend_handles_labels()
lgd = ax.legend(handles, labels, loc='upper center', bbox_to_anchor=(0.5,-0.1))
ax.grid(which='major', color='gray', linewidth=1)
ax.grid(which='minor')
ax.minorticks_on()
print('Drawing html/cup{}.png'.format(week))
plt.savefig('html/cup{}.png'.format(week), bbox_extra_artists=(lgd,), bbox_inches='tight')
plt.close('all')

if dolastweek:
    fig, ax = plt.subplots()
    weeks.pop()
    for t in teams:
        team = t[1]
        a = [x[0] for x in c1.execute('SELECT points FROM points WHERE teamid=? ORDER BY week', (t[0],))]
        a.pop()
        print(weeks)
        print(a)
        ax.plot(weeks, np.cumsum(a), label=team)
    handles, labels = ax.get_legend_handles_labels()
    lgd = ax.legend(handles, labels, loc='upper center', bbox_to_anchor=(0.5,-0.1))
    ax.grid(which='major', color='gray', linewidth=1)
    ax.grid(which='minor')
    ax.minorticks_on()
    print('Drawing html/cup{}.png'.format(week - 1))
    plt.savefig('html/cup{}.png'.format(week - 1), bbox_extra_artists=(lgd,), bbox_inches='tight')
    plt.close('all')
  
runners = c1.execute('SELECT * FROM runners').fetchall()
for r in runners:
    wlog = c1.execute('SELECT week, COALESCE(time,0), COALESCE(distance,0) FROM wlog WHERE runnerid=?', (r[0],)).fetchall()
    norm = c1.execute('SELECT goal*7/365 FROM runners WHERE runnerid=?', (r[0],)).fetchall()[0][0]
    norm = round(norm, 2)
    paces = [w[1]/w[2] if w[2]>0 else np.nan for w in wlog]
    dists = [w[2] if w[2]>0 else np.nan for w in wlog]
    cumdists = [w[2] if w[2]>0 else 0 for w in wlog]
    print(r[1])
    print('paces')
    print(paces)
    print('dists')
    print(dists)
    wlog = list(map(list, zip(*wlog)))
    ticks = list(range(60*int((np.nanmin(paces)//60)-1), 60*int((np.nanmax(paces)//60)+1), 10))
    labels = [sec2min(i) for i in ticks]
    fig, ax = plt.subplots()
    ax.set_yticks(ticks)
    ax.set_yticklabels(labels)
    ax.set_xticks([int(i) for i in wlog[0]])
    ax.tick_params(axis = 'y', labelcolor = 'blue')
    ax.yaxis.grid(which = 'minor', linestyle = '-')
    ax.invert_yaxis()
    ax.grid(which = 'major', color = 'gray', linewidth = 1)
    ax.minorticks_on() 

    ax.plot(wlog[0], paces, color = 'blue', label = 'Темп')

    ax2 = ax.twinx()
    ticks2 = list(range(0, 10*int(np.nanmax(dists)+10//10), 10))
    ax2.set_yticks(ticks2)
    ax2.tick_params(axis='y', labelcolor='red')
#    ax2.grid(which='minor')
#    ax2.grid(which='major', color='gray', linewidth=1)
#    ax2.minorticks_on()
    ax2.plot(wlog[0], dists, color='red', label='Расстояние')
    ax2.axhline(y = norm, linewidth = 1, color = 'red', linestyle='--') #dashes = (10,10))
    lines, labels = ax.get_legend_handles_labels()
    lines2, labels2 = ax2.get_legend_handles_labels()
    ax2.legend(lines + lines2 + [Line2D([0], [0], color='red', lw=1, linestyle='--')], 
            labels + labels2 + ['Норма ({} км)'.format(norm)],
            loc='best')

    fig.savefig('html/u{}.png'.format(r[0]))

    plt.gca()
    fig, ax3 = plt.subplots()
    print('cumdists:')
    print(cumdists)
    sumdists = sum(cumdists)
    ax3.plot(wlog[0], np.cumsum(cumdists), color='red', label='Расстояние={} км'.format(round(sum(cumdists)),2))
    norms = [i*norm for i in range(1, wlog[0][-1] + 1)]
    print('norms')
    print(norms)
#    ax3.set_yticks(ticks)
#    ax3.set_yticklabels(labels)
#    ax3.set_xticks([int(i) for i in wlog[0]])
#    ax3.tick_params(axis = 'y', labelcolor = 'blue')
    ax3.grid(which = 'minor', linestyle = '-')
#    ax3.invert_yaxis()
    ax3.grid(which = 'major', color = 'gray', linewidth = 1)
    ax3.minorticks_on() 
    ax3.plot(range(1, wlog[0][-1]+1), norms, color='red', label='Норма={} км'.format(round(norms[-1]),2), lw=1, ls='--')
    ax3.legend()
    fig.savefig('html/w{}.png'.format(r[0]))
    plt.close('all')
