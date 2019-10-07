.PHONY: all clean docs

PROJECTS = $(sort $(notdir $(basename $(wildcard data/projects/*.toml))))

all: $(CURDIR)/deps/asciideck docs
	PATH=$(CURDIR)/deps/asciideck/scripts:$(PATH) hugo --theme=ninenines -d ..

server: $(CURDIR)/deps/asciideck
	PATH=$(CURDIR)/deps/asciideck/scripts:$(PATH) hugo server --theme=ninenines

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
		if [ "$1" = "cowboy" -o "$1" = "gun" -o "$1" = "cowlib" ] || [ "$1" = "ranch" -a "$3" = "1.6" ] || [ "$1" = "ranch" -a "$3" = "1.7" ] || [ "$1" = "ranch" -a "$3" = "2.0" ]; then \
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
			if [ "$1" = "cowboy" -o "$1" = "gun" -o "$1" = "cowlib" ] || [ "$1" = "ranch" -a "$3" = "1.6" ] || [ "$1" = "ranch" -a "$3" = "1.7" ] || [ "$1" = "ranch" -a "$3" = "2.0" ]; then \
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

tmp/$1:
	cd tmp && git clone $(repository)

.PHONY: docs-$1 $(foreach t,$(TARGETS),docs-$1-$t)

$(eval $(foreach t,$(TARGETS),$(call docs-version-target,$1,$t,$(word $t,$(VERSIONS)),$(word $t,$(BRANCHES)))))

docs-$1: tmp $(foreach t,$(TARGETS),docs-$1-$t)

docs:: docs-$1

endef

$(eval $(foreach p,$(filter-out erlang.mk,$(PROJECTS)),$(call docs-target,$p)))
