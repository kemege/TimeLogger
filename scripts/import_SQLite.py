import sqlite3
import datetime
import calendar
import xml.etree.ElementTree as etree
import sys
import random
import MySQLdb

MAX_TITLE = 1024


def main():
    sdb = sqlite3.connect(sys.argv[1])
    sc = sdb.cursor()
    groups = {}
    aliases = {}
    mdb = MySQLdb.connect(
        sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], charset='utf8mb4'
        )
    mc = mdb.cursor()
    timePattern = '%Y-%m-%d %H:%M:%S'

    # fetch groups
    for row in sc.execute('''
        SELECT GroupId, TextData FROM `group`
        WHERE TimelineId = 3 ORDER BY GroupId
        '''):
        tree = etree.fromstring(row[1])
        path = tree.find('FullPath').text
        groups[int(row[0])] = path if path is not None else 'Unknown'
        alias = tree.find('Description').text
        aliases[int(row[0])] = alias if alias is not None else ''

    # fetch active activities
    for row in sc.execute('''
        SELECT GroupId, DisplayName, StartUtcTime, EndUtcTime
        FROM `activity` WHERE TimelineId = 3 ORDER BY ActivityId
        '''):
        title = row[1]
        if len(title) > MAX_TITLE:
            title = title[0:MAX_TITLE//2-1] + '..' + title[-MAX_TITLE//2+1:]
        groupId = int(row[0])
        path = groups[groupId]
        begin = calendar.timegm(
            datetime.datetime.strptime(row[2][:-4], timePattern).timetuple()
            )
        finish = calendar.timegm(
            datetime.datetime.strptime(row[3][:-4], timePattern).timetuple()
            )

        # check path existence
        mc.execute('SELECT id FROM program WHERE path = %s LIMIT 1', (path,))
        row = mc.fetchone()
        if row:
            program = row[0]
        else:
            color = '{0:06X}'.format(random.randint(0, 256**3))
            mc.execute(
                'INSERT INTO program (path, color, alias) VALUES (%s, %s, %s)',
                (path, color, aliases[groupId])
                )
            program = mdb.insert_id()
        mc.execute(
            'INSERT INTO activity (title, program, begin, finish, idle, duration) \
            VALUES (%s, %s, %s, %s, %s, %s)',
            (title, program, begin, finish, 0, finish - begin)
            )
    # fetch idle activities
    # check idle program existence
    mc.execute('SELECT id FROM program WHERE path = %s LIMIT 1', ('Idle',))
    row = mc.fetchone()
    if row:
        program = row[0]
    else:
        color = '{0:06X}'.format(random.randint(0, 256**3))
        mc.execute(
            'INSERT INTO program (path, color) VALUES (%s, %s)',
            (path, color)
            )
        program = mdb.insert_id()

    for row in sc.execute('''
        SELECT StartUtcTime, EndUtcTime
        FROM `activity` WHERE TimelineId = 2 AND GroupId = 2
        ORDER BY ActivityId
        '''):
        begin = calendar.timegm(
            datetime.datetime.strptime(row[0][:-4], timePattern).timetuple()
            )
        finish = calendar.timegm(
            datetime.datetime.strptime(row[1][:-4], timePattern).timetuple()
            )
        mc.execute(
            'INSERT INTO activity (title, program, begin, finish, idle, duration) \
            VALUES (%s, %s, %s, %s, %s, %s)',
            ('Idle', program, begin, finish, 0, finish - begin)
            )

    sc.close()
    sdb.close()
    mdb.commit()
    mc.close()
    mdb.close()


def help():
    print('''Usage: {0} <SQLite Filename> <MySQL Address> <MySQL Username> \
<MySQL Password> <MySQL DB Name>
Transport activity data from SQLite database from ManicTime into MySQL \
database for TimeLogger
        '''.format(sys.argv[0]))

if __name__ == '__main__':
    if len(sys.argv) == 6:
        main()
    else:
        help()
