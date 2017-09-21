#!/usr/bin/python

import os
import re
import glob
import string

# * TODO [[view:./test/ver0/test.c::face=ovl-face1::linb=9::colb=1::cole=6][I found an error ./test/ver0/test.c::9]]


def findfiles(rootdir, regex):
    print regex
    for root, dirs, files in os.walk(rootdir):
        for name in files:
            test = os.path.join(root, name)
            if re.search(regex, test) != None:
                yield test

class Defect():
    position = ""
    filename = ""

    def __init__(self, deadfile):
        self.deadfile = deadfile

    def position(self):
        data = file(self.deadfile).readlines()[0].split(':')
        return data[1], data[2]

    def type(self):
        return self.deadfile.split(".")[-2:]

    def orgstring(self):
        data = dict()
        data["file"], data["line"] = self.position()
        data['file'] = os.path.join(os.path.split(self.deadfile)[0], os.path.split(data['file'])[1])
        data['type'] = ' '.join(self.type())
        return string.Template("* TODO [[view:${file}::face=ovl-face1::linb=${line}::colb=0::cole=2][$type]]").substitute(data)

if __name__ == "__main__":
    import sys
    for i in findfiles(sys.argv[1], re.compile("%s$" % sys.argv[2][2:].replace('.', '\\.'))):
        de = Defect(i)
        print de.orgstring()

