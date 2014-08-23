from xml.etree import ElementTree
from collections import defaultdict
from pprint import pformat
from ftplib import FTP
import sys
import os
import json
import urllib2
import re

def parse_repositories(root):
    default = None
    repos = {}
    for repo in root.findall("repository"):
        repos[repo.get("name")] = repo.get("href")
        if repo.get("default") == "yes":
            default = repo.get("name")
    return repos, default

def parse_modules(root, repos, default):
    parent_map = dict((c, p) for p in root.getiterator() for c in p)
    modules = []
    for branch in root.findall("*/branch"):
        repo = repos[branch.get("repo") or default]
        if branch.get("module") is None:
            continue
        path = os.path.dirname(os.path.dirname(branch.get("module")))
        version = branch.get("version")
        modules.append({ "repo": repo, "path": path, "version": version, "name": parent_map[branch].get("id")})
    return modules

def update_gnome(modules, root):
    ftp = FTP("ftp.gnome.org")
    ftp.login()
    try:
        for module in modules:
            basepath = os.path.join(module["repo"][21:], module["path"])

            data = []
            path = os.path.join(basepath, "cache.json")
            ftp.retrbinary("RETR " + path, data.append)

            content = json.loads("".join(data))
            latest_version = content[2].values()[0][-1]
            files = content[1].values()[0][latest_version]

            data = []
            path = os.path.join(basepath, files["sha256sum"])
            ftp.retrbinary("RETR " + path, data.append)
            sha256, filename = "".join([x for x in "".join(data[0]).split("\n") if ".tar.xz" in x]).split()

            node = root.findall("autotools[@id='%s']/branch" % module["name"])[0]
            node.set("module", os.path.join(module["path"], files["tar.xz"]))
            node.set("hash", "sha256:" + sha256)
            node.set("version", latest_version)
    finally:
        ftp.close()

def update_cairo(modules, root):
    url = "http://cairographics.org/releases/"
    request = urllib2.Request(url)
    listing = urllib2.urlopen(request).read()
    for module, ext in [("cairo", "xz"), ("pixman", "gz")]:
        version = re.findall("LATEST-%s-([^\"]+\d)\"" % module, listing)[0]
        request = urllib2.Request(os.path.join(url, "%s-%s.tar.%s.sha1" % (module, version, ext)))
        sha1, filename = urllib2.urlopen(request).read().split()
        node = root.findall("autotools[@id='%s']/branch" % module)[0]
        node.set("hash", "sha1:" + sha1)
        node.set("module", filename)
        node.set("version", version)

if __name__ == "__main__":
    tree = ElementTree.parse(sys.argv[1])
    root = tree.getroot()

    repos, default = parse_repositories(root)
    modules = parse_modules(root, repos, default)

    update_gnome([x for x in modules if "ftp.gnome.org" in x["repo"] and "gee" not in x["name"]], root)
    update_cairo([x for x in modules if "cairo" in x["repo"]], root)

    print ElementTree.tostring(root)
