.PHONY: all docs serve

all: docs

serve:
	$(MAKE) -C $(CURDIR)/server serve

$(CURDIR)/tmp/asciideck:
	mkdir -p $(CURDIR)/tmp
	if [ ! -d $(CURDIR)/tmp/asciideck/.git ]; then \
		git clone https://github.com/ninenines/asciideck $(CURDIR)/tmp/asciideck; \
	fi
	$(MAKE) -C $(CURDIR)/tmp/asciideck

# Manual HTML. Arguments are name, title, repository, versions, branches,
# and has_guide (true or empty).
# $1 name, $2 title, $3 repository, $4 versions, $5 branches, $6 has_guide
define docs-html-manual-target

.PHONY: docs-html-manual-$1

docs-html-manual-$1: $(CURDIR)/tmp/asciideck
	set -e -o pipefail; \
	mkdir -p $(CURDIR)/tmp/manual; \
	if [ ! -d $(CURDIR)/tmp/manual/$1/.git ]; then \
		git clone $3 $(CURDIR)/tmp/manual/$1; \
	fi; \
	versions="$4"; \
	branches="$5"; \
	links=$(CURDIR)/tmp/$1-version-links.html; \
	head=$(CURDIR)/templates/head.html; \
	foot=$(CURDIR)/templates/foot.html; \
	asciidoc=$(CURDIR)/tmp/asciideck/scripts/asciidoc; \
	: > $$$$links; \
	for version in $$$$versions; do \
		printf '    <li><a href="/docs/en/$1/%s/manual">%s</a></li>\n' "$$$$version" "$$$$version" >> $$$$links; \
	done; \
	wrap() { \
		title="$$$$1"; body="$$$$2"; out="$$$$3"; ver="$$$$4"; \
		mkdir -p "$$$$(dirname "$$$$out")"; \
		rm -f "$$$$out"; \
		cat $$$$head \
			| sed -e "s|{{TITLE}}|$$$$title|g" \
				-e 's/{{ACTIVE_ARTICLES}}//' \
				-e 's/{{ACTIVE_TALKS}}//' \
				-e 's/{{ACTIVE_DOCS}}/ class="active"/' \
			>> "$$$$out"; \
		cat "$$$$body" >> "$$$$out"; \
		if [ "$6" = true ]; then \
			printf '    <li><a href="/docs/en/$1/%s/guide">User Guide</a></li>\n' "$$$$ver" > $(CURDIR)/tmp/$1-doc-links.html; \
			printf '    <li><a href="/docs/en/$1/%s/manual">Function Reference</a></li>\n' "$$$$ver" >> $(CURDIR)/tmp/$1-doc-links.html; \
		else \
			printf '    <li><a href="/docs/en/$1/%s/manual">Function Reference</a></li>\n' "$$$$ver" > $(CURDIR)/tmp/$1-doc-links.html; \
		fi; \
		{ \
			sed -n '1,/{{DOC_LINKS}}/p' $$$$foot | sed '$$$$d'; \
			cat $(CURDIR)/tmp/$1-doc-links.html; \
			sed -n '/{{DOC_LINKS}}/,/{{VERSION_LINKS}}/p' $$$$foot | sed '1d;$$$$d'; \
			cat $$$$links; \
			sed -n '/{{VERSION_LINKS}}/,$$$$p' $$$$foot | sed '1d'; \
		} | sed -e 's|{{PREV_NEXT}}||' \
			-e 's/{{PROJECT}}/$2/' \
			-e 's/{{VERSION}}/'"$$$$ver"'/g' \
			-e 's/{{DOCTYPE}}/Function Reference/' \
			>> "$$$$out"; \
	}; \
	i=1; \
	for version in $$$$versions; do \
		branch=$$$$(echo $$$$branches | cut -d' ' -f $$$$i); \
		i=$$$$((i + 1)); \
		git -C $(CURDIR)/tmp/manual/$1 checkout -f $$$$branch; \
		git -C $(CURDIR)/tmp/manual/$1 reset --hard $$$$branch; \
		stage=$(CURDIR)/tmp/html/$1/$$$$version/manual; \
		rm -rf $$$$stage; \
		mkdir -p $$$$stage; \
		sed '1,/^$$$$/d' $(CURDIR)/tmp/manual/$1/doc/src/manual/$1_app.asciidoc \
			| sed 's/link:man:\([a-z0-9_]*\)(7)/link:\1_app/g' \
			| sed 's/\(link:man:[a-z0-9_]*\):/\1./g' \
			| sed 's/link:man:\([a-z0-9_.]*\)[1-9()]*/link:\1/g' \
			| $$$$asciidoc --no-header-footer --safe - \
			> $(CURDIR)/tmp/$1-index.html; \
		wrap "$2 Function Reference" $(CURDIR)/tmp/$1-index.html $$$$stage/index.html $$$$version; \
		for f in $(CURDIR)/tmp/manual/$1/doc/src/manual/*.asciidoc; do \
			base=$$$$(basename "$$$$f" .asciidoc); \
			title=$$$$(sed -n '1,/^= .*/ s/^= //p' "$$$$f"); \
			sed '1,/^$$$$/d' "$$$$f" \
				| sed 's/link:man:$1(7)/link:../g' \
				| sed 's/\(link:man:[a-z0-9_]*\):/\1./g' \
				| sed 's/link:man:\([a-z0-9_.]*\)[1-9()]*/link:..\/\1/g' \
				| $$$$asciidoc --no-header-footer --safe - \
				> $(CURDIR)/tmp/$1-page.html; \
			wrap "$$$$title" $(CURDIR)/tmp/$1-page.html $$$$stage/$$$$base/index.html $$$$version; \
		done; \
		dest=$(CURDIR)/../docs/en/$1/$$$$version/manual; \
		rm -rf $$$$dest; \
		mkdir -p $$$$(dirname $$$$dest); \
		mv $$$$stage $$$$dest; \
	done

docs-html-targets += docs-html-manual-$1

endef

# Guide HTML. Same arguments as the manual target, without has_guide.
# Chapter order comes from book.asciidoc includes. Version links point at /guide.
# $1 name, $2 title, $3 repository, $4 versions, $5 branches
define docs-html-guide-target

.PHONY: docs-html-guide-$1

docs-html-guide-$1: $(CURDIR)/tmp/asciideck
	set -e -o pipefail; \
	mkdir -p $(CURDIR)/tmp/guide; \
	if [ ! -d $(CURDIR)/tmp/guide/$1/.git ]; then \
		git clone $3 $(CURDIR)/tmp/guide/$1; \
	fi; \
	versions="$4"; \
	branches="$5"; \
	links=$(CURDIR)/tmp/$1-guide-version-links.html; \
	head=$(CURDIR)/templates/head.html; \
	foot=$(CURDIR)/templates/foot.html; \
	asciidoc=$(CURDIR)/tmp/asciideck/scripts/asciidoc; \
	names=$(CURDIR)/tmp/$1-guide-names; \
	titles=$(CURDIR)/tmp/$1-guide-titles; \
	: > $$$$links; \
	for version in $$$$versions; do \
		printf '    <li><a href="/docs/en/$1/%s/guide">%s</a></li>\n' "$$$$version" "$$$$version" >> $$$$links; \
	done; \
	wrap() { \
		title="$$$$1"; body="$$$$2"; out="$$$$3"; ver="$$$$4"; nav="$$$$5"; \
		mkdir -p "$$$$(dirname "$$$$out")"; \
		rm -f "$$$$out"; \
		cat $$$$head \
			| sed -e "s|{{TITLE}}|$$$$title|g" \
				-e 's/{{ACTIVE_ARTICLES}}//' \
				-e 's/{{ACTIVE_TALKS}}//' \
				-e 's/{{ACTIVE_DOCS}}/ class="active"/' \
			>> "$$$$out"; \
		cat "$$$$body" >> "$$$$out"; \
		printf '    <li><a href="/docs/en/$1/%s/guide">User Guide</a></li>\n' "$$$$ver" > $(CURDIR)/tmp/$1-guide-doc-links.html; \
		printf '    <li><a href="/docs/en/$1/%s/manual">Function Reference</a></li>\n' "$$$$ver" >> $(CURDIR)/tmp/$1-guide-doc-links.html; \
		{ \
			if [ -n "$$$$nav" ]; then cat "$$$$nav"; fi; \
			sed -n '/{{PREV_NEXT}}/,/{{DOC_LINKS}}/p' $$$$foot | sed '1d;$$$$d'; \
			cat $(CURDIR)/tmp/$1-guide-doc-links.html; \
			sed -n '/{{DOC_LINKS}}/,/{{VERSION_LINKS}}/p' $$$$foot | sed '1d;$$$$d'; \
			cat $$$$links; \
			sed -n '/{{VERSION_LINKS}}/,$$$$p' $$$$foot | sed '1d'; \
		} | sed -e 's/{{PROJECT}}/$2/' \
			-e 's/{{VERSION}}/'"$$$$ver"'/g' \
			-e 's/{{DOCTYPE}}/User Guide/' \
			>> "$$$$out"; \
	}; \
	i=1; \
	for version in $$$$versions; do \
		branch=$$$$(echo $$$$branches | cut -d' ' -f $$$$i); \
		i=$$$$((i + 1)); \
		git -C $(CURDIR)/tmp/guide/$1 checkout -f $$$$branch; \
		git -C $(CURDIR)/tmp/guide/$1 reset --hard $$$$branch; \
		book=$(CURDIR)/tmp/guide/$1/doc/src/guide/book.asciidoc; \
		if [ ! -f $$$$book ]; then \
			continue; \
		fi; \
		grep '^include::' $$$$book | sed 's/include::\([a-z0-9_.]*\)\.asciidoc.*/\1/' > $$$$names; \
		: > $$$$titles; \
		while read -r name; do \
			title=$$$$(sed -n '1,/^== .*/ s/^== //p' $(CURDIR)/tmp/guide/$1/doc/src/guide/$$$$name.asciidoc); \
			printf '%s\n' "$$$$title" >> $$$$titles; \
		done < $$$$names; \
		stage=$(CURDIR)/tmp/html/$1/$$$$version/guide; \
		rm -rf $$$$stage; \
		mkdir -p $$$$stage; \
		book_title=$$$$(sed -n '1,/^= .*/ s/^= //p' $$$$book); \
		sed -E 's/include::([a-z0-9_.]*)\.asciidoc(.*)/\* link:\1\/\2/' $$$$book \
			| sed -n '/^= /,$$$$p' \
			| sed -n '/^$$$$/,$$$$p' \
			| sed 's/^= /== /' \
			| $$$$asciidoc --no-header-footer --safe - \
			> $(CURDIR)/tmp/$1-guide-index.html; \
		wrap "$$$$book_title" $(CURDIR)/tmp/$1-guide-index.html $$$$stage/index.html $$$$version ""; \
		for f in $(CURDIR)/tmp/guide/$1/doc/src/guide/*.asciidoc; do \
			base=$$$$(basename "$$$$f" .asciidoc); \
			if [ "$$$$base" = book ]; then continue; fi; \
			title=$$$$(sed -n '1,/^== .*/ s/^== //p' "$$$$f"); \
			sed '1,/^$$$$/d' "$$$$f" \
				| sed 's/^=== /== /' \
				| sed 's/xref:/link:..\//g' \
				| sed 's/image::/image::..\//g' \
				| sed 's/link:man:$1[(]7[)]/link:\/docs\/en\/$1\/'"$$$$version"'\/manual\/$1_app/g' \
				| sed 's/\(link:man:[a-z0-9_]*\):/\1./g' \
				| sed 's/link:man:\([a-z0-9_.]*\)[1-9()]*/link:\/docs\/en\/$1\/'"$$$$version"'\/manual\/\1/g' \
				| $$$$asciidoc --no-header-footer --safe - \
				> $(CURDIR)/tmp/$1-guide-page.html; \
			nav=""; \
			lineno=$$$$(grep -n -x -F -m 1 "$$$$base" $$$$names | cut -d: -f1 || true); \
			if [ -n "$$$$lineno" ]; then \
				nav=$(CURDIR)/tmp/$1-guide-nav.html; \
				prev_name=""; prev_title=""; next_name=""; next_title=""; \
				if [ "$$$$lineno" -gt 1 ]; then \
					prev_i=$$$$((lineno - 1)); \
					prev_name=$$$$(sed -n "$$$${prev_i}p" $$$$names); \
					prev_title=$$$$(sed -n "$$$${prev_i}p" $$$$titles); \
				fi; \
				next_i=$$$$((lineno + 1)); \
				next_name=$$$$(sed -n "$$$${next_i}p" $$$$names); \
				next_title=$$$$(sed -n "$$$${next_i}p" $$$$titles); \
				{ \
					echo '<nav style="margin:1em 0">'; \
					if [ -n "$$$$prev_name" ]; then \
						printf '    <a style="float:left" href="/docs/en/$1/%s/guide/%s/">%s</a>\n' "$$$$version" "$$$$prev_name" "$$$$prev_title"; \
					fi; \
					if [ -n "$$$$next_name" ]; then \
						printf '    <a style="float:right" href="/docs/en/$1/%s/guide/%s/">%s</a>\n' "$$$$version" "$$$$next_name" "$$$$next_title"; \
					fi; \
					echo '</nav>'; \
				} > "$$$$nav"; \
			fi; \
			wrap "$$$$title" $(CURDIR)/tmp/$1-guide-page.html $$$$stage/$$$$base/index.html $$$$version "$$$$nav"; \
		done; \
		for a in $(CURDIR)/tmp/guide/$1/doc/src/guide/*; do \
			if [ ! -f "$$$$a" ]; then continue; fi; \
			case "$$$$a" in \
				*.asciidoc|*.sty) continue ;; \
			esac; \
			cp "$$$$a" $$$$stage/; \
		done; \
		dest=$(CURDIR)/../docs/en/$1/$$$$version/guide; \
		rm -rf $$$$dest; \
		mkdir -p $$$$(dirname $$$$dest); \
		mv $$$$stage $$$$dest; \
	done

docs-html-targets += docs-html-guide-$1

endef

# Manuals for every project. Guides too when has_guide is true.
# $1 name, $2 title, $3 repository, $4 versions, $5 branches, $6 has_guide
define docs-html-project
$(call docs-html-manual-target,$1,$2,$3,$4,$5,$6)
$(if $(filter true,$6),$(call docs-html-guide-target,$1,$2,$3,$4,$5))
endef

$(eval $(call docs-html-project,cowboy,Cowboy,https://github.com/ninenines/cowboy,2.20 2.19 2.18,2.20.0 2.19.0 2.18.0,true))
$(eval $(call docs-html-project,cowlib,Cowlib,https://github.com/ninenines/cowlib,2.21 2.20 2.19,2.21.0 2.20.0 2.19.0,))
$(eval $(call docs-html-project,gun,Gun,https://github.com/ninenines/gun,2.7 2.6 2.5,2.7.0 2.6.0 2.5.0,true))
$(eval $(call docs-html-project,ranch,Ranch,https://github.com/ninenines/ranch,2.3 2.2 1.8,2.3.0 2.2.1 1.8.1,true))

docs: $(docs-html-targets)
