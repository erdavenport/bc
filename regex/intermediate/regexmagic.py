"""regexmagic provides a cell magic for the IPython Notebook called
%%regex that runs regular expressions against lines of text without
the clutter of re.search(...) calls.  The output is colorized to show
the span of each match.

Usage:

%%regex a+b
this text has no matches
this line has one match: aaab
about to match some more: aab

or:

%%regex pattern
@filename

Note: IPython presently interprets {x} to mean 'expand variable x', so
      regular expressions like '\d{4}' must be written as '\d{{4}}'.
      We're working on it..."""

# This file is copyright 2013 by Matt Davis and Greg Wilson and
# covered by the license at
# https://github.com/gvwilson/regexmagic/blob/master/LICENSE

import re
from IPython.core.magic import Magics, magics_class, cell_magic
from IPython.display import display, HTML

PATTERN_TEMPL = '<p><font color="green"><strong>{0}</strong></font></p>\n'
MATCH_TEMPL = '<font color="{0}"><u>{1}</u></font>'

@magics_class
class RegexMagic(Magics):
    '''Provide the 'regex' calling point for the magic, and keep track of
    alternating colors while matching.'''

    this_color, next_color = 'red', 'blue'

    @cell_magic
    def regex(self, pattern, text):
        pattern_str = PATTERN_TEMPL.format(pattern)
        text = self.get_text(text)
        results = [self.handle_line(pattern, line) for line in text.rstrip().split('\n')]
        display(HTML(pattern_str + self.tablify(results)))

    def get_text(self, text):
        if text[0] == '@':
            filename = text[1:]
            with open(filename, 'r') as reader:
                text = reader.read()
        return text

    def handle_line(self, pattern, line):
        result = []
        m = re.search(pattern, line)
        marker = '*' if m else '&nbsp;'
        while m:
            result.append(line[:m.start()])
            result.append(MATCH_TEMPL.format(self.this_color, line[m.start():m.end()]))
            self.this_color, self.next_color = self.next_color, self.this_color
            line = line[m.end():]
            m = re.search(pattern, line)
        result.append(line)
        return marker, ''.join(result)

    def tablify(self, results):
        return '<table border="0">' + ''.join(self.rowify(*r) for r in results) + '</table>'

    def rowify(self, marker, line):
        return '<tr><td>{0}</td><td>{1}</td></tr>'.format(marker, line)

def load_ipython_extension(ipython):
    ipython.register_magics(RegexMagic)
