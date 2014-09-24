#!/usr/bin/env python
# encoding: utf-8
# Dominik Fischer, 2014 (XZS)

"""
Automatically fills a template from an authors file.

Example::

    bld(features = 'authors',
        authors = 'AUTHORS',
        template = 'template.txt.in',
        terget = 'template.txt',
        categories = {
            "authors": ["architects", "developers"],
            "artists": "artists"
    })

This will create a file "template.txt", by copying "template.txt.in", replacing
all occurrences of "$authors" with the names found under the headlines
"architects" and "developers" in "AUTHORS" and "$artists" with the names found
under "artists" therein.

Omitting "categories" maps all variables to headings of the same name,
"authors" defaults to "AUTHORS", "template" is mandatory, and "target" can be
left out to be the same as "template" stripped from its ".in" prefix.
"""

from waflib.TaskGen import feature
from waflib.Task import Task
from string import Template
from re import compile, escape
from pickle import dumps
from operator import itemgetter

class split:
    """
    Dissects an iterable starting a new iterator whenever
    a separator is encountered, discarding the separator.
    """
    def __init__(self, iterable, separator):
        self.separator = separator
        self.it = iter(iterable)

    def __iter__(self):
        return self

    def _step(self):
        self.current = next(self.it)

    def __next__(self):
        self._step()
        return self._subiter()

    next = __next__
    def _subiter(self):
        while self.current != self.separator:
            yield self.current
            self._step()

REPLACEMENTS = {
    '<': '&lt;',
    '>': '&gt;',
    ' at ': '@',
    ' dot ': '.'
}

def replace(dict, text):
    """Replaces every dict key with its value."""
    regex = compile("|".join(map(escape, dict.keys())))
    return regex.sub(lambda x: dict[x.group(0)], text)

class idict:
    """Identity dictionary. Returns key as value."""
    def __getitem__(self, key):
        return [key]

    def items(self):
        return ()

def lastname(name):
    """Extracts the authors last name, or whatever comes before the email address."""
    name = name.split()
    try:
        return name[-2]
    except IndexError:
        return name[0]

class template(Task):
    def __init__(self, *k, **kw):
        super(template, self).__init__(*k, **kw)
        self.categories = getattr(kw['generator'], 'categories', idict())

    def run(self):
        groups = {group[0]: set(group[2:]) for group in (
            list(category) for category in split(
                self.inputs[0].read().splitlines(), ''))}
        self.outputs[0].write(
            Template(self.inputs[1].read()).safe_substitute({
                category: '\n'.join(
                    sorted(
                        (replace(REPLACEMENTS, person) for person in (
                            set.union(*[groups[heading] for heading in headings]))),
                        key=lastname))
                for category, headings in self.categories.items()}))

    def sig_vars(self):
        super(template, self).sig_vars()
        for k, v in sorted(self.categories.items(), key=itemgetter(0)):
            self.m.update(dumps(k))
            for e in v:
                self.m.update(dumps(e))

@feature('authors')
def authors_template(gen):
    path = gen.path
    template = path.find_node(gen.template)
    authors = path.find_node(getattr(gen, 'authors', 'AUTHORS'))
    if gen.target == '':
        target = template.change_ext('', ext_in='.in')
    else:
        target = path.find_or_declare(gen.target)
    gen.create_task('template', [authors, template], target)
