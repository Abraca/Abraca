#!/usr/bin/python
from subprocess import check_output
import os
import re


authorchanges = {}
prevrelease = "HEAD"
prevdate = "Not released"
prevtreehash = "HEAD"

for line in check_output("git log --pretty=format:'%t\t%an\t%ai\t%d\t%s'", shell=True).split("\n"):
    line = line.strip()
    if not line:
        continue

    parts = line.strip().split("\t", 4)
    if len(parts) == 5:
        treehash, author, date, refs, subject = parts
    else:
        treehash, author, date, refs, subject = parts + ["No Subject"]

    if subject.lower().startswith("merge"):
        continue

    matches = re.findall("(tag: (\d(\.\d+)*))", refs)
    if matches:
        subject = matches[0][1]
        if len(authorchanges) == 0:
            prevrelease = matches[0][1]
            prevtreehash = treehash
            prevdate = date.split()[0]
            continue
        print "Changes between %s and %s" % (subject, prevrelease)
        print
        print " Release date: %s" % prevdate
        print " Authors contributing to this release: %d" % len(authorchanges)
        print " Number of changesets: %d" % sum(map(len, authorchanges.values()))
        print " Number of files in this release: %s" % check_output("git ls-tree -r %s | wc -l" % prevtreehash, shell=True).strip()
        print
        authors = authorchanges.keys()
        authors.sort()
        for a in authors:
            print " %s:" % a
            changes = authorchanges[a]
            changes.sort()
            for c in changes:
                print "  * %s" % c
            print
        print
        print
        authorchanges={}
        prevrelease = subject
        prevtreehash = treehash
        prevdate = date.split()[0]
        continue

    if author not in authorchanges:
        authorchanges[author] = []

    authorchanges[author].append(subject)
