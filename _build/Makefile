.PHONY: all clean docs wrap-doc docs-html-cowlib serve

.NOTPARALLEL:

PROJECTS = $(sort $(notdir $(basename $(wildcard data/projects/*.toml))))

all: $(CURDIR)/deps/asciideck docs
	PATH=$(CURDIR)/deps/asciideck/scripts:$(PATH) hugo --theme=ninenines -d ..

server: $(CURDIR)/deps/asciideck
	PATH=$(CURDIR)/deps/asciideck/scripts:$(PATH) hugo server --theme=ninenines

serve:
	$(MAKE) -C $(CURDIR)/server serve

$(CURDIR)/deps/asciideck:
	mkdir -p $(CURDIR)/deps
	git clone git@github.com:ninenines/asciideck.git $(CURDIR)/deps/asciideck
	$(MAKE) -C $(CURDIR)/deps/asciideck

clean: DOC_FILES = $(filter-out static/docs/en/cowboy/1.0/guide,$(wildcard static/docs/en/*/*/guide))
clean: OUTPUT_FILES = $(filter-out ../_build,$(wildcard ../*))
clean:
	rm -rf content/docs tmp
	$(if $(OUTPUT_FILES),rm -rf $(OUTPUT_FILES))
	$(if $(DOC_FILES),rm -rf $(DOC_FILES))

tmp: clean
	mkdir tmp/

# For substitution.
comma := ,
quote := "
# Necessary comment to fix syntax highlighting: "

define docs-version-target

.PHONY: docs-$1-$2

docs-$1-$2: tmp/$1
	cd tmp/$1 && git checkout $4 && git reset --hard $4
	if [ -f tmp/$1/doc/src/guide/book.asciidoc ]; then \
		mkdir -p content/docs/en/$1/$3/guide/; \
		echo "+++" > content/docs/en/$1/$3/guide.asciidoc; \
		echo -n "title = \"" >> content/docs/en/$1/$3/guide.asciidoc; \
		echo -n `sed -n '1,/^= .*/ s/^= //p' tmp/$1/doc/src/guide/book.asciidoc` \
			>> content/docs/en/$1/$3/guide.asciidoc; \
		echo "\"" >> content/docs/en/$1/$3/guide.asciidoc; \
		printf "%s\n" "project = \"$1\"" "version = \"$3\"" "doctype = \"guide\"" \
			>> content/docs/en/$1/$3/guide.asciidoc; \
		echo "+++" >> content/docs/en/$1/$3/guide.asciidoc; \
		sed -E 's/include::([a-z0-9_.]*)\.asciidoc(.*)/* link:\1\/\2/' tmp/$1/doc/src/guide/book.asciidoc \
			| sed -n '/^= /,$$$$p' \
			| sed -n '/^$$$$/,$$$$p' \
			| sed 's/^= /== /' >> content/docs/en/$1/$3/guide.asciidoc; \
		mv tmp/$1/doc/src/guide/book.asciidoc tmp/$1/doc/src/guide/book.asciidoc.bak; \
		for f in tmp/$1/doc/src/guide/*.asciidoc; do \
			printf "%s\n" "+++" "project = \"$1\"" "version = \"$3\"" "doctype = \"guide\"" \
				> content/docs/en/$1/$3/guide/`basename $$$$f`; \
			echo -n "title = \"" >> content/docs/en/$1/$3/guide/`basename $$$$f`; \
			echo -n `sed -n '1,/^== .*/ s/^== //p' $$$$f` >> content/docs/en/$1/$3/guide/`basename $$$$f`; \
			echo "\"" >> content/docs/en/$1/$3/guide/`basename $$$$f`; \
			echo -n "weight = " >> content/docs/en/$1/$3/guide/`basename $$$$f`; \
			echo "`cat tmp/$1/doc/src/guide/book.asciidoc.bak | grep ^include:: | sed 's/include::\(.*.asciidoc\).*/\1/'` :`basename $$$$f`" | tr '\n' ' ' | awk -F: '{print index($$$$1, $$$$2)}' >> content/docs/en/$1/$3/guide/`basename $$$$f`; \
			echo "+++" >> content/docs/en/$1/$3/guide/`basename $$$$f`; \
			echo >> content/docs/en/$1/$3/guide/`basename $$$$f`; \
			sed '1,/^$$$$/d' $$$$f | sed 's/^=== /== /' \
				| sed 's/xref:/link:..\//g' | sed 's/image::/image::..\//g' \
				| sed 's/link:man:$1[(]7[)]/link:\/docs\/en\/$1\/$3\/manual\/$1_app/g' \
				| sed 's/\(link:man:[a-z0-9_]*\):/\1./g' \
				| sed 's/link:man:\([a-z0-9_.]*\)[1-9()]*/link:\/docs\/en\/$1\/$3\/manual\/\1/g' \
				>> content/docs/en/$1/$3/guide/`basename $$$$f`; \
		done; \
		rm tmp/$1/doc/src/guide/book.asciidoc.bak; \
		mkdir -p static/docs/en/$1/$3/guide/; \
		cp tmp/$1/doc/src/guide/* static/docs/en/$1/$3/guide/; \
	fi
	if [ -f tmp/$1/doc/src/manual/$1_app.asciidoc ]; then \
		mkdir -p content/docs/en/$1/$3/manual/; \
		printf "%s\n" "+++" "title = \"`sed 's/\(.\)/\U\1/' <<< $1` Function Reference\"" \
			"project = \"$1\"" "version = \"$3\"" "doctype = \"manual\"" "+++" "" \
			> content/docs/en/$1/$3/manual.asciidoc; \
		if [ "$1" = "cowboy" -o "$1" = "gun" -o "$1" = "cowlib" -o "$1" = "ranch" ]; then \
			sed '1,/^$$$$/d' tmp/$1/doc/src/manual/$1_app.asciidoc \
				| sed 's/link:man:\([a-z0-9_]*\)(7)/link:\1_app/g' \
				| sed 's/\(link:man:[a-z0-9_]*\):/\1./g' \
				| sed 's/link:man:\([a-z0-9_.]*\)[1-9()]*/link:\1/g' \
				>> content/docs/en/$1/$3/manual.asciidoc; \
		else \
			for f in `ls tmp/$1/doc/src/manual/*.asciidoc | sort`; do \
				echo -n "* link:`basename $$$$f .asciidoc`[" >> content/docs/en/$1/$3/manual.asciidoc; \
				echo -n `sed -En '0,/^= / s/= (.*)/\1/ p' $$$$f` >> content/docs/en/$1/$3/manual.asciidoc; \
				echo "]" >> content/docs/en/$1/$3/manual.asciidoc; \
			done; \
		fi; \
		for f in tmp/$1/doc/src/manual/*.asciidoc; do \
			printf "%s\n" "+++" "project = \"$1\"" "version = \"$3\"" "doctype = \"manual\"" \
				> content/docs/en/$1/$3/manual/`basename $$$$f`; \
			echo -n "title = \"" >> content/docs/en/$1/$3/manual/`basename $$$$f`; \
			echo -n `sed -n '1,/^= .*/ s/^= //p' $$$$f` >> content/docs/en/$1/$3/manual/`basename $$$$f`; \
			echo "\"" >> content/docs/en/$1/$3/manual/`basename $$$$f`; \
			echo "+++" >> content/docs/en/$1/$3/manual/`basename $$$$f`; \
			echo >> content/docs/en/$1/$3/manual/`basename $$$$f`; \
			if [ "$1" = "cowboy" -o "$1" = "gun" -o "$1" = "cowlib" -o "$1" = "ranch" ]; then \
				sed '1,/^$$$$/d' $$$$f \
					| sed 's/link:man:$1(7)/link:../g' \
					| sed 's/\(link:man:[a-z0-9_]*\):/\1./g' \
					| sed 's/link:man:\([a-z0-9_.]*\)[1-9()]*/link:..\/\1/g' \
					>> content/docs/en/$1/$3/manual/`basename $$$$f`; \
			else \
				sed '1,/^$$$$/d' $$$$f \
					| sed 's/link:man:$1(7)/link:..\/$1_app/g' \
					| sed 's/\(link:man:[a-z0-9_]*\):/\1./g' \
					| sed 's/link:man:\([a-z0-9_.]*\)[1-9()]*/link:..\/\1/g' \
					>> content/docs/en/$1/$3/manual/`basename $$$$f`; \
			fi \
		done \
	fi

endef

define docs-target

$(eval include data/projects/$1.toml)
$(eval VERSIONS := $(subst $(quote),,$(subst $(comma),,$(subst ],,$(subst [,,$(versions))))))
$(eval BRANCHES := $(subst $(comma),,$(subst ],,$(subst [,,$(branches)))))
$(eval TARGETS := $(shell echo "1 2 3 4 5 6 7 8 9" | cut -d' ' -f 1-$(words $(VERSIONS))))

tmp/$1: | tmp
	cd tmp && git clone $(repository)

.PHONY: docs-$1 $(foreach t,$(TARGETS),docs-$1-$t)

$(eval $(foreach t,$(TARGETS),$(call docs-version-target,$1,$t,$(word $t,$(VERSIONS)),$(word $t,$(BRANCHES)))))

docs-$1: tmp $(foreach t,$(TARGETS),docs-$1-$t)

docs:: docs-$1

endef

$(eval $(foreach p,$(filter-out erlang.mk cowlib,$(PROJECTS)),$(call docs-target,$p)))

docs:: docs-html-cowlib

# Rebuild one published doc page into tmp/ from its body and the shell
# templates. Does not write under docs/ and does not run Hugo.
wrap-doc:
	mkdir -p $(CURDIR)/tmp
	rm -f $(CURDIR)/tmp/getting_started.html
	cat $(CURDIR)/templates/head.html \
		| sed -e 's/{{TITLE}}/Getting started/g' \
			-e 's/{{ACTIVE_ARTICLES}}//' \
			-e 's/{{ACTIVE_TALKS}}//' \
			-e 's/{{ACTIVE_DOCS}}/ class="active"/' \
			-e 's/{{ACTIVE_SERVICES}}//' \
		>> $(CURDIR)/tmp/getting_started.html
	cat $(CURDIR)/../docs/en/cowboy/2.20/guide/getting_started/index.html \
		| sed -n '/<h1 class="lined-header">/,/<nav style="margin:1em 0">/ { /<h1 class="lined-header">/d; /<nav style="margin:1em 0">/d; p; }' \
		>> $(CURDIR)/tmp/getting_started.html
	cat $(CURDIR)/templates/foot.html \
		| sed -e 's|{{PREV_NEXT}}|<nav style="margin:1em 0">\n    <a style="float:left" href="https://ninenines.eu/docs/en/cowboy/2.20/guide/introduction/">Introduction</a>\n    <a style="float:right" href="https://ninenines.eu/docs/en/cowboy/2.20/guide/flow_diagram/">Flow diagram</a>\n</nav>|' \
			-e 's|{{DOC_LINKS}}|    <li><a href="/docs/en/cowboy/2.20/guide">User Guide</a></li>\n    <li><a href="/docs/en/cowboy/2.20/manual">Function Reference</a></li>|' \
			-e 's|{{VERSION_LINKS}}|    <li><a href="/docs/en/cowboy/2.20/guide">2.20</a></li>\n    <li><a href="/docs/en/cowboy/2.19/guide">2.19</a></li>\n    <li><a href="/docs/en/cowboy/2.18/guide">2.18</a></li>\n    <li><a href="/docs/en/cowboy/2.17/guide">2.17</a></li>\n    <li><a href="/docs/en/cowboy/2.16/guide">2.16</a></li>|' \
			-e 's/{{PROJECT}}/Cowboy/' \
			-e 's/{{VERSION}}/2.20/g' \
			-e 's/{{DOCTYPE}}/User Guide/' \
		>> $(CURDIR)/tmp/getting_started.html

# Cowlib manual data. Hugo still reads data/projects/cowlib.toml for the
# other projects; this target does not.
COWLIB_REPOSITORY = https://github.com/ninenines/cowlib
COWLIB_TITLE = Cowlib
COWLIB_VERSIONS = 2.21 2.20 2.19 2.18 2.17
COWLIB_BRANCHES = 2.21.0 2.20.0 2.19.0 2.18.0 2.17.1

# Build every Cowlib manual with asciideck and the shell.
# Cowlib is not part of the Hugo docs rules, so Hugo will not overwrite these.
docs-html-cowlib: $(CURDIR)/deps/asciideck
	mkdir -p $(CURDIR)/tmp
	if [ ! -d $(CURDIR)/tmp/cowlib/.git ]; then \
		git clone $(COWLIB_REPOSITORY) $(CURDIR)/tmp/cowlib; \
	fi
	set -e -o pipefail; \
	versions="$(COWLIB_VERSIONS)"; \
	branches="$(COWLIB_BRANCHES)"; \
	links=$(CURDIR)/tmp/cowlib-version-links.html; \
	head=$(CURDIR)/templates/head.html; \
	foot=$(CURDIR)/templates/foot.html; \
	asciidoc=$(CURDIR)/deps/asciideck/scripts/asciidoc; \
	: > $$links; \
	for version in $$versions; do \
		printf '    <li><a href="/docs/en/cowlib/%s/manual">%s</a></li>\n' "$$version" "$$version" >> $$links; \
	done; \
	wrap() { \
		title="$$1"; body="$$2"; out="$$3"; ver="$$4"; \
		mkdir -p "$$(dirname "$$out")"; \
		rm -f "$$out"; \
		cat $$head \
			| sed -e "s|{{TITLE}}|$$title|g" \
				-e 's/{{ACTIVE_ARTICLES}}//' \
				-e 's/{{ACTIVE_TALKS}}//' \
				-e 's/{{ACTIVE_DOCS}}/ class="active"/' \
				-e 's/{{ACTIVE_SERVICES}}//' \
			>> "$$out"; \
		cat "$$body" >> "$$out"; \
		{ \
			sed -n '1,/{{VERSION_LINKS}}/p' $$foot | sed '$$d'; \
			cat $$links; \
			sed -n '/{{VERSION_LINKS}}/,$$p' $$foot | sed '1d'; \
		} | sed -e 's|{{PREV_NEXT}}||' \
			-e 's|{{DOC_LINKS}}|    <li><a href="/docs/en/cowlib/'"$$ver"'/manual">Function Reference</a></li>|' \
			-e 's/{{PROJECT}}/$(COWLIB_TITLE)/' \
			-e 's/{{VERSION}}/'"$$ver"'/g' \
			-e 's/{{DOCTYPE}}/Function Reference/' \
			>> "$$out"; \
	}; \
	i=1; \
	for version in $$versions; do \
		branch=$$(echo $$branches | cut -d' ' -f $$i); \
		i=$$((i + 1)); \
		git -C $(CURDIR)/tmp/cowlib checkout -f $$branch; \
		git -C $(CURDIR)/tmp/cowlib reset --hard $$branch; \
		stage=$(CURDIR)/tmp/html/cowlib/$$version/manual; \
		rm -rf $(CURDIR)/tmp/html/cowlib/$$version; \
		mkdir -p $$stage; \
		sed '1,/^$$/d' $(CURDIR)/tmp/cowlib/doc/src/manual/cowlib_app.asciidoc \
			| sed 's/link:man:\([a-z0-9_]*\)(7)/link:\1_app/g' \
			| sed 's/\(link:man:[a-z0-9_]*\):/\1./g' \
			| sed 's/link:man:\([a-z0-9_.]*\)[1-9()]*/link:\1/g' \
			| $$asciidoc --no-header-footer --safe - \
			> $(CURDIR)/tmp/cowlib-index.html; \
		wrap "$(COWLIB_TITLE) Function Reference" $(CURDIR)/tmp/cowlib-index.html $$stage/index.html $$version; \
		for f in $(CURDIR)/tmp/cowlib/doc/src/manual/*.asciidoc; do \
			base=$$(basename "$$f" .asciidoc); \
			title=$$(sed -n '1,/^= .*/ s/^= //p' "$$f"); \
			sed '1,/^$$/d' "$$f" \
				| sed 's/link:man:cowlib(7)/link:../g' \
				| sed 's/\(link:man:[a-z0-9_]*\):/\1./g' \
				| sed 's/link:man:\([a-z0-9_.]*\)[1-9()]*/link:..\/\1/g' \
				| $$asciidoc --no-header-footer --safe - \
				> $(CURDIR)/tmp/cowlib-page.html; \
			wrap "$$title" $(CURDIR)/tmp/cowlib-page.html $$stage/$$base/index.html $$version; \
		done; \
		dest=$(CURDIR)/../docs/en/cowlib/$$version/manual; \
		rm -rf $$dest; \
		mkdir -p $$(dirname $$dest); \
		mv $$stage $$dest; \
	done; \
	rm -rf $(CURDIR)/content/docs/en/cowlib
