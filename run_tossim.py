#! /usr/bin/python
from TOSSIM import *
import sys

t = Tossim([])
r = t.radio()
f = open("topo.txt", "r")

for line in f:
  s = line.split()
  if s:
    print " ", s[0], " ", s[1], " ", s[2];
    r.add(int(s[0]), int(s[1]), float(s[2]))

t.addChannel("Coco", sys.stdout)
t.addChannel("State", sys.stdout)

noise = open("meyer-heavy.txt", "r")
for line in noise:
  str1 = line.strip()
  if str1:
    val = int(str1)
    for i in range(0, 11):
      t.getNode(i).addNoiseTraceReading(val)

for i in range(0, 11):
  print "Creating noise model for ",i;
  t.getNode(i).createNoiseModel();
  t.getNode(i).bootAtTime(100001)

for i in range(100000):
  t.runNextEvent()
