#-----------------------------------------------------------
# Re-make lecture materials.
#-----------------------------------------------------------

# Directories.
OUT = _site
LINK_OUT = /tmp/bc-links
BOOK = _book

# Source Markdown pages.
MARKDOWN_SRC_2 = \
	LICENSE.md \
	NEW_MATERIAL.md \
	bib.md \
	gloss.md \
	$(wildcard hash/intermediate/*.md) \
	$(wildcard web/intermediate/*.md) \
	$(wildcard make/intermediate/*.md) \
	$(wildcard oop/intermediate/*.md) \
	$(wildcard regex/intermediate/*.md)

NOTEBOOK_SRC_2 = \
	$(wildcard hash/intermediate/*.ipynb) \
	$(wildcard web/intermediate/*.ipynb) \
	$(wildcard oop/intermediate/*.ipynb) \
	$(wildcard regex/intermediate/*.ipynb) \
	$(wildcard make/intermediate/*.ipynb)

NOTEBOOK_MD_2 = \
	$(patsubst %.ipynb,%.md,$(NOTEBOOK_SRC_2))

HTML_DST_2 = \
	$(patsubst %.md,$(OUT)/%.html,$(MARKDOWN_SRC_2)) \
	$(patsubst %.md,$(OUT)/%.html,$(NOTEBOOK_MD_2))

BOOK_SRC_2 = \
	$(OUT)/hash/intermediate/index.html $(wildcard $(OUT)/hash/intermediate/*-*.html) \
	$(OUT)/web/intermediate/index.html $(wildcard $(OUT)/web/intermediate/*-*.html) \
	$(OUT)/oop/intermediate/index.html $(wildcard $(OUT)/oop/intermediate/*-*.html) \
	$(OUT)/regex/intermediate/index.html $(wildcard $(OUT)/regex/intermediate/*-*.html) \
	$(OUT)/make/intermediate/index.html $(wildcard $(OUT)/make/intermediate/*-*.html) \
	$(OUT)/bib.html \
	$(OUT)/gloss.html \
	$(OUT)/LICENSE.html

.SECONDARY : $(NOTEBOOK_MD_2)

#-----------------------------------------------------------

# Default action: show available commands (marked with double '#').
all : commands

## check    : build site.
check : $(OUT)/index.html

# Build HTML versions of Markdown source files using Jekyll.
$(OUT)/index.html : $(MARKDOWN_SRC_2) $(NOTEBOOK_MD_2)
	jekyll -t build -d $(OUT)
	mv $(OUT)/NEW_MATERIAL.html $(OUT)/index.html

# Build Markdown versions of IPython Notebooks.
%.md : %.ipynb
	ipython nbconvert --template=./swc.tpl --to=markdown --output="$(subst .md,,$@)" "$<"

book : book.html

book.html : $(BOOK_SRC_2)
	python bin/make-book.py $^ > $@

#-----------------------------------------------------------

## commands : show all commands
commands :
	@grep -E '^##' Makefile | sed -e 's/## //g'

## fixme    : find places where fixes are needed.
fixme :
	@grep -n FIXME $$(find -f bash git python sql -type f -print | grep -v .ipynb_checkpoints)

## gloss    : check glossary
gloss :
	@bin/gloss.py ./gloss.md $(MARKDOWN_DST) $(NOTEBOOK_DST)

## images   : create a temporary page to display images
images :
	@bin/make-image-page.py $(MARKDOWN_SRC) $(NOTEBOOK_SRC) > image-page.html
	@echo "Open ./image-page.html to view images"

## links    : check links
# Depends on linklint, an HTML link-checking module from
# http://www.linklint.org/, which has been put in bin/linklint.
# Look in output directory's 'error.txt' file for results.
links :
	@bin/linklint -doc $(LINK_OUT) -textonly -root $(OUT) /@

## clean    : clean up
clean :
	@rm -rf $(OUT) $(NOTEBOOK_MD) $$(find . -name '*~' -print) $$(find . -name '*.pyc' -print)

## show     : show variables
show :
	@echo "MARKDOWN_SRC" $(MARKDOWN_SRC)
	@echo "NOTEBOOK_SRC" $(NOTEBOOK_SRC)
	@echo "NOTEBOOK_MD" $(NOTEBOOK_MD)
	@echo "HTML_DST" $(HTML_DST)
