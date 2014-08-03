#!/usr/bin/env python
from subprocess import check_output, call
import tarfile
import os

def get_template(ball, path):
    template = {}

    tfile = tarfile.open(ball, "r")

    reference = tfile.getmember(path)
    for attr in ('uid', 'gid', 'uname', 'gname', 'mtime'):
        template[attr] = getattr(reference, attr)

    tfile.close()

    return template

def add_files(ball, prefix, template, files):
    tfile = tarfile.open(ball, "a")

    for name, content in files:
        path = os.path.join(os.path.dirname(ball), name)
        if os.path.exists(path):
            os.unlink(path)

        fd = file(path, "w+")
        fd.write(content)
        fd.close()

        tinfo = tfile.gettarinfo(arcname=os.path.join(prefix, name), name=path)
        for key, value in template.items():
            setattr(tinfo, key, value)

        fd = file(path)
        tfile.addfile(tinfo, fileobj=fd)
        fd.close()

    tfile.close()

VERSION = check_output(["git", "describe"]).strip()

SUBZERO_DIR="external/subzero"

PREFIX="abraca-%s" % VERSION
PREFIX_SUBZERO="%s/%s" % (PREFIX, SUBZERO_DIR)

DIST_DIR="dist"
DIST_ABRACA="%s/abraca-%s.tar" % (DIST_DIR, VERSION)
DIST_ABRACA_BZ2="%s/abraca-%s.tar.bz2" % (DIST_DIR, VERSION)
DIST_SUBZERO="%s/abraca-subzero-%s.tar" % (DIST_DIR, VERSION)

if not os.path.exists(DIST_DIR):
    os.mkdir(DIST_DIR)

if os.path.exists(DIST_ABRACA):
    os.unlink(DIST_ABRACA)

if os.path.exists(DIST_ABRACA_BZ2):
    os.unlink(DIST_ABRACA_BZ2)

if os.path.exists(DIST_SUBZERO):
    os.unlink(DIST_SUBZERO)

# Tar up ABRACA
call("git archive --format=tar --prefix=%s/ HEAD > %s" % (PREFIX, DIST_ABRACA), shell=True)

# Checkout and tar up the SUBZEROs
call("git submodule init", shell=True)
call("git submodule update", shell=True)
call("git --git-dir=%s/.git archive --format=tar --prefix=%s/ HEAD > %s" % (SUBZERO_DIR, PREFIX_SUBZERO, DIST_SUBZERO), shell=True)

# Append the SUBZEROs to the ABRACA archive
call("tar -Af %s %s" % (DIST_ABRACA, DIST_SUBZERO), shell=True)

# Append ChangeLog and a summary of all file hashes."
add_files(DIST_ABRACA, PREFIX, get_template(DIST_ABRACA, os.path.join(PREFIX, "wscript")), [
        ("abraca-%s.ChangeLog" % VERSION, check_output("utils/gen-changelog.py")),
        ("checksums", check_output("utils/gen-tree-hashes.py"))
])

call("bzip2 %s" % DIST_ABRACA, shell=True)
