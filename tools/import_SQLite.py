import sqlite3
import json
import datetime
import calendar
import xml.etree.ElementTree as etree
import sys
import random
import MySQLdb

def main():
    sdb = sqlite3.connect(sys.argv[1])
    sc = sdb.cursor()
    groups = {}
    activities = []
    mdb = MySQLdb.connect(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], charset='utf8')
    mc = mdb.cursor()

    # fetch groups
    for row in sc.execute("SELECT GroupId, TextData FROM `group` WHERE TimelineId = 3 ORDER BY GroupId"):
        tree = etree.fromstring(row[1])
        path = tree.find('FullPath').text
        groups[int(row[0])] = path


    # fetch activities
    for row in sc.execute("SELECT GroupId, DisplayName, StartUtcTime, EndUtcTime FROM `activity`\
                               WHERE TimelineId = 3 ORDER BY ActivityId LIMIT 1"):
        title = row[1]
        path = groups[int(row[0])]
        begin = calendar.timegm(datetime.datetime.strptime(row[2][:-4], '%Y-%m-%d %H:%M:%S').timetuple())
        finish = calendar.timegm(datetime.datetime.strptime(row[3][:-4], '%Y-%m-%d %H:%M:%S').timetuple())

        # check path existence
        mc.execute('SELECT id FROM program WHERE path = %s LIMIT 1', (path,))
        row = mc.fetchone()
        if row:
            program = row[0]
        else:
            color = '{0:06X}'.format(random.randint(0, 256**3))
            mc.execute('INSERT INTO program (path, color) VALUES (%s, %s)', (path, color))
            program = mdb.insert_id()
        mc.execute('INSERT INTO activity (title, program, begin, finish, idle, duration) VALUES (%s, %s, %s, %s, %s, %s)', 
            (title, program, begin, finish, 0, finish - begin))
    sc.close()
    sdb.close()
    mdb.commit()
    mc.close()
    mdb.close()

def help():
    print('''Usage: {0} <SQLite Filename> <MySQL Address> <MySQL Username> <MySQL Password> <MySQL DB Name>
Transport activity data from SQLite database from ManicTime into MySQL database for TimeLogger
        '''.format(sys.argv[0]))

if __name__ == '__main__':
    if len(sys.argv) == 6:
        main()
    else:
        help()
