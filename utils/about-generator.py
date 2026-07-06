#!/usr/bin/env python3
# encoding: utf-8
#
# Generate a Vala file exposing credit lists parsed from an AUTHORS file, for
# use with Adw.AboutWindow (developers/artists/translator_credits).
#
# Usage:
#   about-generator.py AUTHORS output.vala
#
# AUTHORS format is `Heading\n------\nName <email>\nName <email>\n\n...`.
# Emails are de-obfuscated ("a at b dot c" -> "a@b.c") and angle brackets kept
# so Adw renders them as mailto links.
#
import sys

# Vala array name -> AUTHORS headings that feed it.
CATEGORIES = {
    "developers": ["Original Abraca design", "Developers", "Code Contributions"],
    "artists": ["Logo", "Additional art"],
    "translators": ["Translators"],
}

REPLACEMENTS = [
    (" at ", "@"),
    (" dot ", "."),
]


def deobfuscate(text):
    for needle, repl in REPLACEMENTS:
        text = text.replace(needle, repl)
    return text


def lastname(name):
    parts = name.split()
    try:
        return parts[-2]
    except IndexError:
        return parts[0]


def parse_authors(path):
    groups = {}
    heading = None
    with open(path, encoding="utf-8") as fh:
        lines = [line.rstrip("\n") for line in fh]
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            heading = None
            i += 1
            continue
        if i + 1 < len(lines) and set(lines[i + 1].strip()) == {"-"}:
            heading = line.strip()
            groups.setdefault(heading, set())
            i += 2
            continue
        if heading is not None:
            groups[heading].add(line.strip())
        i += 1
    return groups


def vala_string(text):
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def main():
    authors_path, output_path = sys.argv[1:3]
    groups = parse_authors(authors_path)

    lines = [
        "/* Generated from AUTHORS by utils/about-generator.py. Do not edit. */",
        "namespace Abraca.About {",
    ]
    for name, headings in CATEGORIES.items():
        people = set()
        for heading in headings:
            people |= groups.get(heading, set())
        entries = sorted((deobfuscate(p) for p in people), key=lastname)
        lines.append("\tpublic const string[] %s = {" % name)
        for entry in entries:
            lines.append("\t\t%s," % vala_string(entry))
        lines.append("\t};")
    lines.append("}")

    with open(output_path, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
