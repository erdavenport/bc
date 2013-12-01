*   [Introduction](00-intro.html)
*   [Simple Patterns](01-basic.html)
*   [Operators](02-operators.html)
*   [Under the Hood](03-mechanics.html)
*   [More Patterns](04-patterns.html)
*   [More Tools](05-tools.html)

Our job is to read 20 or 30 files,
each of which contains several hundred measurements of background evil levels,
and convert them into a uniform format for further processing.
Each of the readings has the name of the site where the reading was taken,
the date the reading was taken on,
and of course the background evil level in millivaders.
The problem is, these files are formatted in different ways.
Here is the first one:

    Site    Date    Evil (millivaders)
    ----    ----    ------------------
    Baker 1 2009-11-17      1223.0
    Baker 1 2010-06-24      1122.7
    Baker 2 2009-07-24      2819.0
    Baker 2 2010-08-25      2971.6
    Baker 1 2011-01-05      1410.0
    Baker 2 2010-09-04      4671.6
    ...

A single tab character divides the fields in each row into columns.
The site names contain spaces,
and the dates are in international standard format:
four digits for the year,
two for the month,
and two for the day.

> ### Tabs vs. Spaces
>
> FIXME: Explain tabs and spaces.

Let's have a look at the second notebook:

    Site/Date/Evil
    Davison/May 22, 2010/1721.3
    Davison/May 23, 2010/1724.7
    Pertwee/May 24, 2010/2103.8
    Davison/June 19, 2010/1731.9
    Davison/July 6, 2010/2010.7
    Pertwee/Aug 4, 2010/1731.3
    Pertwee/Sept 3, 2010/4981.0
    ...

It uses slashes as separators.
There don't appear to be spaces in the site names,
but the month names and day numbers vary in length.
What's worse,
the months are text, and the order is month-day-year rather than year-month-day.

We could parse these files using basic string operations,
but it would be difficult.
A better approach is to use [regular expressions](../../gloss.html#regular-expression).
A regular expression is just a pattern that can match a string.
They are actually very common:
when we say `*.txt` to a computer,
we mean, "Match all of the filenames that end in `.txt`."
The `*` is a regular expression:
it matches any number of characters.

The rest of this chapter will look at what regular expressions can do,
and how we can use them to handle our data.
A warning before we go any further, though:
the notation for regular expressions is ugly, even by the standards of programming.
We're writing patterns to match strings,
but we're writing those patterns *as* strings
using only the symbols that are on the keyboard,
instead of inventing new symbols the way mathematicians do.
The good news is that regular expressions work more or less the same way
in almost every programming language.
We will present examples in Python,
but the ideas and notation transfer directly to Perl, Java, MATLAB, C#, and Fortran.

Simple Patterns
---------------

Let's start by reading data from two files,
discarding the headers,
and keeping the first few lines of each:

    readings = []
    for filename in ('data-1.txt', 'data-2.txt'):
        lines = open(filename, 'r').read().strip().split('\n')
        readings += lines[2:8]

    for r in readings:
        print r

This puts six lines from the first data file and six from the second
into the list `readings`:

    Baker 1 2009-11-17      1223.0
    Baker 1 2010-06-24      1122.7
    Baker 2 2009-07-24      2819.0
    Baker 2 2010-08-25      2971.6
    Baker 1 2011-01-05      1410.0
    Baker 2 2010-09-04      4671.6
    Davison/May 23, 2010/1724.7
    Pertwee/May 24, 2010/2103.8
    Davison/June 19, 2010/1731.9
    Davison/July 6, 2010/2010.7
    Pertwee/Aug 4, 2010/1731.3
    Pertwee/Sept 3, 2010/4981.0</span>

We will test our regular expressions against this data
to see how well we are matching different record formats as we go along.

Without regular expressions,
we can select records that have the month "06" using `if '06' in record`:

    for r in readings:
        if '06' in r:
            print r

    Baker 1 2010-06-24      1122.7

If we want to select data for two months
we have to use `if ('06' in record) or ('07' in record)`.

    for r in readings:
        if ('06' in r) or ('07' in r):
            print r

    Baker 1 2010-06-24      1122.7
    Baker 2 2009-07-24      2819.0

But if we say `'05' in record`
it can match against the day "05" as well as the month "05".
We can try to write a more complicated test
that only looks for the two-digit month in a particular place in the string,
but let's try using a regular expression instead.

We will work up to our solution in stages.
We start by importing the regular expressions library,
then examine each record in `readings`.
If a regular expression search can find a match
for the string `'06'` in the record,
we print it out:

import re
for r in readings:
  if re.search('06', r):
    print r
Baker 1 2010-06-24      1122.7

So far, this does the same thing as `'06' in r`.
But if we want to match `'06'` or `'07'`,
regular expressions let us combine the two comparisons in a single expression:

import re
for r in readings:
  if re.search('06|07', r):
    print r
Baker 1 2010-06-24      1122.7
Baker 2 2009-07-24      2819.0

The first argument to `re.search` is the pattern we are searching for,
written as a string.
The second argument is the data we are searching in.
It's easy to reverse these accidentally,
i.e., to put the data first and the pattern second.
This can be hard to track down, so please be careful.

The vertical bar in the pattern means "or".
It tells regular expression library that
we want to match either the text on the left,
or the text on the right.
As we will see <a href="#s:mechanics">later</a>,
the regular expression library can look for both patterns
in a single operation.

We are going to be throwing a lot of regular expressions against our data,
so let's write a function that will tell us which records match a particular pattern.
Our function `show_matches` takes a pattern and a list of strings as arguments.
It prints out two stars as a marker
if the pattern matches a string,
and just indents with blanks if it does not:

def show_matches(pattern, strings):
  for s in strings:
    if re.search(pattern, s):
      print '**', s
    else:
      print '  ', s

If we use this function to match `'06|07'` against the data we read in earlier,
it prints stars beside the two records
that have month `'06'` or month `'07'`:

show_matches('06|07', readings)
   Baker 1  2009-11-17  1223.0
** Baker 1  2010-06-24  1122.7
** Baker 2  2009-07-24  2819.0
   Baker 2  2010-08-25  2971.6
   Baker 1  2011-01-05  1410.0
   Baker 2  2010-09-04  4671.6
   Davison/May 23, 2010/1724.7
   Pertwee/May 24, 2010/2103.8
   Davison/June 19, 2010/1731.9
   Davison/July 6, 2010/2010.7
   Pertwee/Aug 4, 2010/1731.3
   Pertwee/Sept 3, 2010/4981.0

But if we change the pattern `'06|7'`
(without a '0' in front of the '7'),
the pattern seems to match a lot of things
that don't have the month `'06'` or `'07'`:

show_matches('06|7', readings)
** Baker 1  2009-11-17  1223.0
** Baker 1  2010-06-24  1122.7
** Baker 2  2009-07-24  2819.0
** Baker 2  2010-08-25  2971.6
   Baker 1  2011-01-05  1410.0
** Baker 2  2010-09-04  4671.6
** Davison/May 23, 2010/1724.7
   Pertwee/May 24, 2010/2103.8
** Davison/June 19, 2010/1731.9
** Davison/July 6, 2010/2010.7
** Pertwee/Aug 4, 2010/1731.3
   Pertwee/Sept 3, 2010/4981.0

To understand why, think back to mathematics.
The expression *ab+c* means "a times b plus c"
because multiplication has higher precedence than addition.
If we want to force the other meaning,
we have to use parentheses and write *a(b+c)*.

The same is true for regular expressions.
Adjacency has higher precedence than "or",
so the pattern `'06|7'` means,
"Either `'06'` or the digit `'7'`".
If we look back at our data, there are a lot of 7's in our file,
and this pattern is matching all of them.

If we want to match `'06'` or `'07'`
without repeating the digit '0',
we have to parenthesize it as `'0(6|7)'`.
Having said that,
most people probably find the expression `'06|07'` more readable anyway.

Let's go back to our function and our data.
If we use the pattern `'05'`,
then as we said earlier,
we will match records that have '05' as the day
as well as those with '05' as the month.
We can force our match to do the right thing by taking advantage of context.
If the date is formatted as YYYY-MM-DD
then there should be a dash `'-'` before and after the month,
but only before the day.
The pattern `'-05-'` should therefore only match a month of '05'.
Sure enough,
if we give this pattern to our function it doesn't match any records.
This is the correct answer,
since we don't have any readings in this sample of our data set for May.

Matching is useful,
but what we really want to do is extract the year, the month, and the day from our data
so that we can reformat them.
Parentheses can help here too:
when a regular expression matches a piece of text,
the library automatically remembers what matched against every parenthesized sub-expression.

Here's a simple example:

match = re.search('(2009|2010|2011)',
                  'Baker 1\t2009-11-17\t1223.0')
print match.group(1)

The first string is our pattern.
It will match 2009, 2010, or 2011,
and the parentheses around it will make the library remember
which of those three strings was matched.
The second string is just the first record from our data.
(Remember, `'\t'` represents a tab.)

When `re.search` is called,
it returns `None` if it doesn't find a match,
or a special [match object](../../gloss.html#match-object) if it did.
The expression `match.group` returns
the text that matched the sub-expression inside the specified set of parentheses
counting from the left.
Since this pattern only has one set of parentheses,
`match.group(1)` returns whatever matched what's inside them.

The way sub-expressions are numbered sometimes trips people up.
While Python normally counts from 0,
the first match in a regular expression is extracted with `match.group(1)`,
the second with 2,
and so forth.
The reason is that `match.group(0)` returns
all of the text that the entire pattern matched.

What if we want to match the month as well as the year?
A regular expression to match legal months would be
`'(01|02|03|04|05|06|07|08|09|10|11|12)'`.
An expression to match days would be three times longer,
which would be hard to type and (more importantly) hard to read.

Instead, we can use the dot character `'.'` to match any single character.
For example,
the expression `'....-..-..'` matches exactly four characters,
and `'....-..-..'` matches four characters,
a dash,
two more characters,
another dash,
and two more characters.
If we put each set of dots in parentheses as `'(....)-(..)-(..)'`
the three groups should record the year, month, and day
each time there's a successful match.

Let's test that out by calling `re.search`
with the pattern we just described and the first record from our data:

match = re.search('(....)-(..)-(..)',
                  'Baker 1\t2009-11-17\t1223.0')
print match.group(1), match.group(2), match.group(3)
2009 11 17

When we print out the three groups,
we get `'2009'`, `'11'`, and `'17'`,
just as we wanted.
Try doing *that* with substring searches&hellip;

To recapitulate,
leters and digits in a pattern match against themselves,
so `'A'` matches an upper-case A.
The vertical bar `'|'` means "or",
a dot `'.'` matches any single character,
and we use parentheses to enforce grouping and to remember things.

Stepping back from the syntax,
we have also seen that
the right way to build a pattern is
to start with something simple that matches part of the data we're working with,
then add to it piece by piece.
We test it against our data each time we make a change,
but also test that it *doesn't* match things that it shouldn't,
because false positive can be very hard to track down.

Operators
---------

Let's go back to those measurements.
Notebook #1 has the site, date, and background evil level
with single tabs as separators.
Some of the site names have spaces,
and the dates are in the international standard format YYYY-MM-DD.
However,
the fields in Notebook #2 are separated by slashes,
and use months' names instead of numbers.
What's more,
some of the month names are three characters long,
while others are four,
and the days are either one or two digits.

Before looking at how to use regular expressions to extract data from Notebook #2,
let's see how we would do it with simple string operations.
If our records look like `'Davison/May 22, 2010/1721.3'`,
we can split on slashes to separate the site, date, and reading.
We could then split the middle field on spaces to get the month, day, and year,
and then remove the comma from the day if it is present
(because some of our readings don't have a comma after the day).

This is a [procedural](../../gloss.html#procedural-programming) way to solve the problem:
we tell the computer what procedure to follow step by step to get an answer.
In contrast, regular expressions are [declarative](../../gloss.html#declarative-programming):
we declare, "This is what we want," and let the computer figure out how to calculate it.

Our first attempt to parse this data will rely on the `*` operator.
It is a [postfix](../../gloss.html#postfix-operator) operator,
just like the 2 in x<sup>2</sup>,
and means, "Zero or more repetitions of the pattern that comes before it".
For example,
`'a*'` matches zero or more 'a' characters,
while `'.*'` matches any sequence of characters
(including the empty string)
because `'.'` matches anything and `'*'` repeats.
Note that the characters matched by `'.*'` do *not* all have to be the same:
the rule is not, "Match a character against the dot, then repeat that match zero or more times,"
but rather, "Zero or more times, match any character."

Here's a test of a simple pattern using `'.*'`:

match = re.search('(.*)/(.*)/(.*)',
                  'Davison/May 22, 2010/1721.3')
print match.group(1)
print match.group(2)
print match.group(3)

In order for the entire pattern to match,
the slashes '/' have to line up exactly,
because '/' only matches against itself.
That constraint ought to make the three uses of `'.*'` match
the site name, date, and reading.
Sure enough, the output is:

Davison
May 22, 2010
1271.3

Unfortunately, we've been over-generous.
Let's put brackets around each group in our output to make matches easier to see,
then apply this pattern to the string `'//'`:

match = re.search('(.*)/(.*)/(.*)',
                  '//')
print '[' + match.group(1) + ']'
print '[' + match.group(2) + ']'
print '[' + match.group(3) + ']'
[]
[]
[]

We don't want our pattern to match invalid records like this
(remember, "Fail early, fail often").
However,
`'.*'` can match the empty string because it is zero occurrences of a character.

Let's try a variation that uses `+` instead of `*`.
`+` is also a postfix operator, but it means "one or more",
i.e., it has to match at least one occurrence of the pattern that comes before it.

match = re.search('(.+)/(.+)/(.+)',
                  '//')
print match
None

As we can see, the pattern `(.+)/(.+)/(.+)`
*doesn't* match a string containing only slashes
because there aren't characters before, between, or after the slashes.
And if we go back and check it against valid data,
it seems to do the right thing:

print re.search('(.+)/(.+)/(.+)',
                'Davison/May 22, 2010/1721.3')
print '[' + m.group(1) + ']'
print '[' + m.group(2) + ']'
print '[' + m.group(3) + ']'
[Davison]
[May 22, 2010]
[1721.3]

We're going to match a lot of patterns against a lot of strings,
so let's write a function to apply a pattern to a piece of text,
report whether it matches or not,
and print out the match groups if it does:

def show_groups(pattern, text):
  m = re.search(pattern, text)
  if m is None:
    print 'NO MATCH'
    return
  for i in range(1, 1 + len(m.groups())):
    print '%2d: %s' % (i, m.group(i))

We'll test our function against the two records we were just using:

show_groups('(.+)/(.+)/(.+)',
            'Davison/May 22, 2010/1721.3')
1: Davison
2: May 22, 2010
3: 1721.3

show_groups('(.+)/(.+)/(.+)',
            '//)
NO MATCH

All right:
if we're using regular expressions to extract the site, date, and reading,
why not add more groups to break up the date while we're at it?

show_groups('(.+)/(.+) (.+), (.+)/(.+)',
            'Davison/May 22, 2010/1721.3')
1: Davison
2: May
3: 22
4: 2010
5: 1721.3

But wait a second: why doesn't this work?

show_groups('(.+)/(.+) (.+), (.+)/(.+)',
            'Davison/May 22 2010/1721.3')
None

The problem is that the string we're trying to match
doesn't have a comma after the day.
There is one in the pattern, so matching fails.

We could try to fix this by putting `'*'` after the comma in the pattern,
but that would match any number of consecutive commas in the data,
which we don't want either.
Instead, let's use a question mark `'?'`,
which is yet another postfix operator meaning, "0 or 1 of whatever comes before it".
Another way of saying this is that the pattern that comes before the question mark is optional.
If we try our tests again,
we get the right answer in both cases:

# with comma in data
show_groups('(.+)/(.+) (.+),? (.+)/(.+)',
            'Davison/May 22, 2010/1721.3')
1: Davison
2: May
3: 22
4: 2010
5: 1721.3

# without comma in data
show_groups('(.+)/(.+) (.+),? (.+)/(.+)',
            'Davison/May 22 2010/1721.3')
1: Davison
2: May
3: 22
4: 2010
5: 1721.3

Let's tighten up our pattern a little bit more.
We *don't* want to match this record:

Davison/May 22, 201/1721.3

because somebody mis-typed the year, entering three digits instead of four.
(Either that,
or whoever took this reading was also using the physics department's time machine.)
We could use four dots in a row to force the pattern to match exactly four digits:

(.+)/(.+) (.+),? (....)/(.+)

but this won't win any awards for readability.
Instead, let's put the digit `4` in curly braces `{}` after the dot:

(.+)/(.+) (.+),? (.{4})/(.+)

In a regular expression,
curly braces with a number between them means,
"Match the pattern exactly this many times".
Since `.` matches any character,
`.{4}` means "match any four characters".

Let's do a few more tests.
Here are some records in which the dates are either correct or mangled:

tests = (
    'Davison/May , 2010/1721.3',
    'Davison/May 2, 2010/1721.3',
    'Davison/May 22, 2010/1721.3',
    'Davison/May 222, 2010/1721.3',
    'Davison/May 2, 201/1721.3',
    'Davison/ 22, 2010/1721.3',
    '/May 22, 2010/1721.3',
    'Davison/May 22, 2010/'
)

And here's a pattern that should match all the records that are correct,
but should fail to match all the records that have been mangled:

pattern = '(.+)/(.+) (.{1,2}),? (.{4})/(.+)'

We are expecting four digits for the year,
and we are allowing 1 or 2 digits for the day,
since the expression `{M,N}` matches a pattern from M to N times.

When we run this pattern against our test data, three records match:

show_matches(pattern, tests)
** Davison/May , 2010/1721.3
** Davison/May 2, 2010/1721.3
** Davison/May 22, 2010/1721.3
   Davison/May 222, 2010/1721.3
   Davison/May 2, 201/1721.3
   Davison/ 22, 2010/1721.3
   /May 22, 2010/1721.3
   Davison/May 22, 2010/

The second and third matches make sense:
'May 2' and 'May 22' are both valid.
But why does 'May' with no date at all match this pattern?
Let's look at that test case more closely:

show_groups('(.+)/(.+) (.{1,2}),? (.{4})/(.+)',
            'Davison/May , 2010/1721.3')
1: Davison
2: May
3: ,
4: 2010
5: 1721.3

The groups are 'Davison' (that looks right),
'May' (ditto),
a ',' on its own (which is clearly wrong),
and then the right year and the right reading.

Here's what's happened.
The space ' ' after 'May' matches the space ' ' in the pattern.
The expression "1 or 2 occurrences of any character"
matches the comma ',' because ',' is a character and it occurs once.
The expression ',
' is then not matched against anything, because it's allowed to match zero characters.
'?' means "optional",
and in this case,
the regular expression pattern matcher is deciding not to match it against anything,
because that's the only way to get the whole pattern to match the whole string.
After that, the second space matches the second space in our data.
This is obviously not what we want,
so let's modify our pattern again:

show_groups('(.+)/(.+) ([0-9]{1,2}),? (.{4})/(.+)',
            'Davison/May , 2010/1721.3')
None

show_groups('(.+)/(.+) ([0-9]{1,2}),? (.{4})/(.+)',
            'Davison/May 22, 2010/1721.3')
1: Davison
2: May
3: 22
4: 2010
5: 1721.3

The pattern `'(.+)/(.+) ([0-9]{1,2}),? (.{4})/(.+)'`
does the right thing for the case where there is no day,
and also for the case where there is one.
It works because
we have used `[0-9]` instead of `'.'`.

In regular expressions,
square brackets `[]` are used to create sets of characters.
For example, the expression `[aeiou]` matches exactly one vowel,
i.e.,
exactly one occurrence of any character in the set.
We can either write these sets out character by character,
as we've done with vowels,
or as "first character '-' last character"
if the characters are in a contiguous range.
This is why `'[0-9]'` matches exactly one digit.

Here's our completed pattern:

(.+)/([A-Z][a-z]+) ([0-9]{1,2}),? ([0-9]{4})/(.+)'

We have added one more feature to it:
the name of the month has to begin with an upper-case letter,
i.e., a character in the set `[A-Z]`,
which must followed by one or more lower-case characters in the set `[a-z]`.

This pattern still isn't perfect:
the day is one or more occurrences of the digits 0 through 9,
which will allow "days" like '0', '00', and '99'.
It's easiest to check for mistakes like this after we convert the day to an integer,
since trying to handle things like leap years with regular expressions
would be like trying to build a house with a Swiss army knife.

Finally,
the year in our final pattern is exactly four digits,
so it's the set of characters `[0-9]` repeated four times.
Again, we will check for invalid values like '0000' after we convert to integer.

Using the tools we've seen so far,
we can write a simple function that will extract the date
from either of the notebooks we have seen so far
and return the year, the month, and the day as strings:

def get_date(record):
  '''Return (Y, M, D) as strings, or None.'''

  # 2010-01-01
  m = re.search('([0-9]{4})-([0-9]{2})-([0-9]{2})',
                record)
  if m:
    return m.group(1), m.group(2), m.group(3)

  # Jan 1, 2010 (comma optional, day may be 1 or 2 digits)
  m = re.search('/([A-Z][a-z]+) ([0-9]{1,2}),? ([0-9]{4})/',
                record)
  if m:
    return m.group(3), m.group(1), m.group(2)

  return None

We start by testing whether the record contains an ISO-formatted date YYYY-MM-DD.
If it does, then we return those three fields right away.
Otherwise, we test the record against a second pattern
to see if we can find the name of a month,
one or two digits for the day,
and four digits for the year
with slashes between the fields.
If so, we return what we find, permuting the order to year, month, day.
Finally,
if neither pattern matched we return `None` to signal that
we couldn't find anything in the data.

This is probably the most common way to use regular expressions:
rather than trying to combine everything into one enormous pattern,
we have one pattern for each valid case.
We test of those cases in turn;
if it matches, we return what we found,
and if it doesn't,
we move on to the next pattern.
Writing our code this way make it easier to understand
than using a single monster pattern,
and easier to extend if we have to handle more data formats.

Under the Hood
--------------

The regular expression `'([A-Z][a-z]+) ([0-9]{1,2}),? ([0-9]{4})'`
matches a single upper-case character and one or more lower-case characters,
a space,
one or two digits,
an optional comma,
another space,
and exactly four digits.
That is pretty complex,
and knowing a little about how the computer actually does it
will help us debug regular expressions when they don't do what we want.

Regular expressions are implemented using
[finite state machines](../../gloss.html#finite-state-machine).
Here's a very simple FSM that matches exactly one lower case 'a':

FIXME: diagram

Matching starts with the incoming arrow on the left,
which takes us to the first state in our finite state machine.
The only way to get from there to the second state is to match
the 'a' on the arc between states 1 and 2.
The dot in the middle of the second state means that it's an end state.
We must be in one of these states at the end of our match in order for the match to be valid.

Now that we have an FSM that matches the very simple regular expression `'a'`,
let's see if we can do something a little more interesting.
Here's a finite state machine that matches one or more occurrences of the letter 'a':

FIXME: diagram

The first arc labelled 'a' gets us from the initial state to an end state,
but we don't have to stop there:
the curved arc at the top allows us to match another 'a',
and brings us back to the same state.
We can then match another 'a', and another, and so on indefinitely.
(Note that we don't have to stop in the end state the first time we reach it:
we just have to be in an end state when we run out of input.)
The pattern this FSM matches is `'a+'`,
since one 'a' followed by zero or more others is the same as
one or more occurences of 'a'.

Here's another FSM that matches against the letter 'a' or nothing:

FIXME: diagram

The top arc isn't marked, so that transition is free:
we can go from the first state to the second state without consuming any of our input.
This is "a or nothing", which is the same as `'a?'`,
i.e., an optional character 'a'.

This regular expression looks like the one that matches 'a' one or more times,
except there is an extra arc to get us from the first state to the second
without consuming any input:

FIXME: diagram

It is therefore equivalent to the pattern `'a*'`,
i.e.,
it matches nothing at all (taking that free transition from the first state to the second)
or one or more occurrences of 'a'.
We can simplify this considerably like this:

FIXME: diagram

The simple FSMs we have seen so far are enough to implement
most of the regular expressions in the previous sections.
For example, look at this finite state machine:

FIXME: diagram

We can either take the top route or the bottom.
The top route is `a+`;
the bottom route is a 'b', followed by either a 'c' or a 'd',
so this whole thing is equivalent to
the regular expression `'a+|(b(c|d))'`.
An input string that matches any of these paths will leave us in that final end state.

The most important thing about finite state machines is that
the action they take at a node depends on only
the arcs out of that node and the characters in the target data.
Finite state machines do *not* remember how they got to a particular node:
decision-making is always purely local.

This means that there are many patterns that regular expressions *cannot* match.
For example,
it is impossible to write a regular expression to check if nested parentheses match.
If we want to see whether '(((&hellip;)))' is balanced,
we need some kind of memory,
or at least a counter,
and there isn't any in a finite state machine.

Similarly, if we want to check whether a word contains each vowel only once,
the only way to do it is to write a regular expression with 120 clauses,
that checks for each possible permutation of 'aeiou' explicitly.
We cannot write a regular expression that matches an arbitrary vowel,
and then subtracts that vowel from the set of vowels yet to be matched,
because once again,
that would require some kind of memory,
and finite state machines don't have any.

Despite this limitation, regular expressions are tremendously useful.
The first reason is that they are really fast.
After the computer does some pre-calculation
(essentially, once it turns the regular expression into a finite state machine)
a regular expression can be matched against input by looking at each input character only once.
That means that the time required to find patterns with regular expressions
grows in proportion to the size of the data.
The time required for most other pattern-matching techniques grows much faster,
so if regular expressions can do the job,
they are almost always the most efficient option available.

Another reason for using regular expressions is that
they are more readable than other alternatives.
You might not think so looking at the examples so far,
but imagine writing lines of code to match that same patterns.
Nobody would claim that regular expressions are easy to understand,
but they're a lot easier than two dozen lines of substring operations.

More Patterns
-------------

Now that we know how regular expressions work,
let's have a look at Notebook #3:

Date Site Evil(mvad)
May 29 2010 (Hartnell) 1029.3
May 30 2010 (Hartnell) 1119.2
June 1 2010 (Hartnell) 1319.4
May 29 2010 (Troughton) 1419.3
May 30 2010 (Troughton) 1420.0
June 1 2010 (Troughton) 1419.8
...

It has the date as three fields, the site name in parentheses, and then the reading.
We know how to parse dates in this format,
and the fields are separated by spaces,
but how do we match those parentheses?
The parentheses we have seen in regular expressions so far haven't matched characters:
they have created groups.

The way we solve this problem&mdash;i.e.,
the way we match a literal left parenthesis '(' or right parenthesis ')'&mdash;is
to put a backslash in front of it.
This is another example of an [escape sequence](../../gloss.html#escape-sequence):
just as we use the two-character sequence `'\t'` in a string
to represent a literal tab character,
we use the two-character sequence `'\('` or `'\)'` in a regular expression
to match the literal character '(' or ')'.

To get that backslash '\' into the string, though, we have to escape *it* by doubling it up.
This has nothing to do with regular expressions:
it is Python's rule for putting backslashes in strings.
The string representation of the regular expression that matches an opening parenthesis is
therefore `'\\('`.
This can be confusing, so let's take a look at the various layers involved.

Our program text&mdash;i.e., what's stored in our `.py` file&mdash;looks like this:

# find '()' in text
m = re.search('\\(\\)', text)
...

The file has two backslashes,
an open parenthesis,
two backslashes,
and a close parenthesis inside quotes:

FIXME: diagram

When Python reads that file in,
it turns the two-character sequence '\\' into a single '\' character in the string in memory.
This is the first round of escaping.

FIXME: diagram

When we hand that string '\(\)' to the regular expression library,
it takes the two-character sequence '\('
and turns it into an arc in the finite state machine that matches a literal parenthesis:

FIXME: diagram

Turning this over,
if we want a literal parenthesis to be matched,
we have to give the regular expression library '\('.
If we want to put '\(' in a string,
we have to write it in our `.py` file as '\\('.

With that out of the way, let's go back to Notebook #3.
The regular expression that will extract the five fields from each record is
`'([A-Z][a-z]+)&nbsp;([0-9]{1,2})&nbsp;([0-9]{4})&nbsp;\\((.+)\\)&nbsp;(.+)'`,
which is:

*   a word beginning with an upper-case character followed by one or more lower-case characters,
*   a space,
*   one or two digits,
*   another space,
*   four digits,
*   another space,
*   some stuff involving backslashes and parentheses,
*   another space,
*   and then one or more characters making up the reading.

If we take a closer look at that "stuff",
`'\\('` and `'\\)'` are how we write the regular expressions
that match a literal open parenthesis '(' or close parenthesis ')' character in our data.
The two inner parentheses that don't have backslashes in front of them create a group,
but don't match any literal characters.
We create that group so that we can save the results of the match (in this case, the name of the site).

Now that we know how to work with backslahes in regular expressions,
we can take a look at character sets that come up frequently enough to deserve their own abbreviations.
If we use `'\d'` in a regular expression it matches the digits 0 through 9.
If we use `'\s'`, it matches the whitespace characters,
space, tab, carriage return, and newline.
`'\w'` matches word characters;
it's equivalent to the set `'[A-Za-z0-9_]'`
of upper-case letters, lower-case letters, digits, and the underscore.
(It's actually the set of characters that can appear in a variable name in a programming language like C or Python.)
Again, in order to write one of these regular expressions as a string in Python, we have to double the backslashes.

Now that we've seen these character sets,
we can take a look at an example of really bad design.
The regular expression `'\S'` means "non-space characters",
i.e., everything that *isn't* a space, tab, carriage return, or newline.
That might seem to contradict what we said in the previous paragraph,
but if we look closely,
that's an upper-case 'S', not a lower-case 's'.

Similarly, and equally unfortunately,
`'\W'` means "non-word characters" provided it's an upper-case 'W'.
Upper- and lower-case 'S' and 'W' look very similar,
particularly when there aren't other characters right next to them to give context.
This means that these sequences are very easy to mis-type and mis-read.
Everyone eventually uses an upper-case 'S' when they meant to use a lower-case 's' or vice versa,
and then wastes a few hours trying to track it down.
So please, if you're ever designing a library that's likely to be widely used,
try to choose a notation that doesn't make mistakes this easy.

Along with the abbreviations for character sets,
the regular expression library recognizes a few shortcuts for things that aren't actual characters.
For example, if we put a circumflex `'^'` at the start of a pattern,
it matches the beginning of the input text.
(Note that there's no backslash in front of it.)
This means that the pattern `'^mask'` will match the text `'mask size'`,
because the letters 'mask' come at the start of the string,
but will *not* match the word `'unmask'`.
Going to the other end,
if dollar sign `'$'` is the last character in the pattern,
it matches the end of the line rather than a literal '$',
so 'temp$' will match the string 'high-temp',
but not the string 'temperature'.

> ### Regular Expressions and Newlines
>
> The full rule is slightly more complicated.
> By default, regular expressions act as if newline characters were the ends of records.
> For example, the `'.'` pattern matches everything *except* a newline.
> This normally doesn't matter,
> since most I/O routines return one line of text at a time,
> but if we read a whole file into a single string,
> then try to match across line boundaries,
> we may not get the behavior we expect.
> We can use the `MULTILINE` option in our matches to prevent this;
> please see the regular expression documentation for details.

A third shortcut that's often useful is `'\b'`, often called "break".
It doesn't match any characters;
instead, it matches the boundary between word and non-word characters
(where "word" means upper and lower case characters, digits, and the underscore).
For example,
the regular expression `'\bage\b'` will match the string `'the age of'`
because there's a non-word character right before the 'a' and another non-word character right after the 'e'.
That same pattern will not match the word `'phage'`
because there isn't a transition from non-word to word characters, or vice versa, right before the 'a'.
And remember:
to get that regular expression int our program,
we have to escape the backslashes using `'\\bage\\b'`.

One last point to take away from this chapter is that
if we know we are going to use regular expressions to read in data,
we should choose a format for that data that's easy for regular expressions to match.
Optional commas,
tabs that might be repeated,
and other things that make data easy for people to type in
actually make it harder for programs to read that data reliably.
This tension between what's easy for the machine and what's easy for the user never goes away,
but if we're conscious of it,
we can find a happy medium.
