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

# Cross-project man links, shared by the manual and guide recipes.
# $1 is the project being built. The shell function reads version and mf.
define docs-man-links
	man7_url() { \
		proj="$$$$1"; name="$$$$2"; cur="$$$$3"; makefile="$$$$4"; \
		ref=$$$$(sed -n "s/^dep_$$$${name} = git [^ ]* //p" "$$$$makefile" | head -n 1); \
		ver=; \
		case $$$$ref in *.*.*) ver=$$$${ref%.*} ;; esac; \
		case $$$$name in \
			cowboy) published="2.20 2.19 2.18" ;; \
			cowlib) published="2.21 2.20 2.19" ;; \
			gun) published="2.7 2.6 2.5" ;; \
			ranch) published="2.3 2.2 1.8" ;; \
			*) published= ;; \
		esac; \
		case " $$$$published " in \
			*" $$$$ver "*) ;; \
			*) ver= ;; \
		esac; \
		if [ -z "$$$$ver" ]; then \
			case "$$$$proj:$$$$name:$$$$cur" in \
				cowlib:cowboy:2.21) ver=2.20 ;; \
				cowlib:cowboy:2.20) ver=2.19 ;; \
				cowlib:cowboy:2.19) ver=2.18 ;; \
				cowlib:gun:2.21) ver=2.7 ;; \
				cowlib:gun:2.20) ver=2.6 ;; \
				cowlib:gun:2.19) ver=2.5 ;; \
				*) ver=$$$${published%% *} ;; \
			esac; \
		fi; \
		printf '/docs/en/%s/%s/manual/' "$$$$name" "$$$$ver"; \
	}; \
	man_links() { \
		man7_cowboy=; man7_cowlib=; man7_gun=; man7_ranch=; \
		man3sed=; \
		for name in cowboy cowlib gun ranch; do \
			if [ "$$$$name" = $1 ]; then continue; fi; \
			url=$$$$(man7_url $1 "$$$$name" "$$$$version" "$$$$mf"); \
			eval "man7_$$$$name=link:$$$$url"; \
			case $$$$name in \
				cowlib) prefixes="cowlib cow_" ;; \
				*) prefixes=$$$$name ;; \
			esac; \
			for pre in $$$$prefixes; do \
				man3sed="$$$$man3sed -e s|link:man:\($$$${pre}[a-z0-9_.]*\)[1-9()]*|link:$$$$url\1|g"; \
			done; \
		done; \
	}; \
	otp_links() { \
		sed -E \
			-e 's#(^|[^A-Za-z0-9_])ssl\(7\)#\1link:https://www.erlang.org/doc/apps/ssl/ssl_app.html[ssl(7)]#g' \
			-e 's#(^|[^A-Za-z0-9_])ssl\(3\)#\1link:https://www.erlang.org/doc/apps/ssl/ssl.html[ssl(3)]#g' \
			-e 's#(^|[^A-Za-z0-9_])gen_tcp\(3\)#\1link:https://www.erlang.org/doc/apps/kernel/gen_tcp.html[gen_tcp(3)]#g' \
			-e 's#(^|[^A-Za-z0-9_])inet\(3\)#\1link:https://www.erlang.org/doc/apps/kernel/inet.html[inet(3)]#g'; \
	}
endef

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
	$(call docs-man-links,$1); \
	i=1; \
	for version in $$$$versions; do \
		branch=$$$$(echo $$$$branches | cut -d' ' -f $$$$i); \
		i=$$$$((i + 1)); \
		git -C $(CURDIR)/tmp/manual/$1 checkout -f $$$$branch; \
		git -C $(CURDIR)/tmp/manual/$1 reset --hard $$$$branch; \
		mf=$(CURDIR)/tmp/manual/$1/Makefile; \
		man_links; \
		stage=$(CURDIR)/tmp/html/$1/$$$$version/manual; \
		rm -rf $$$$stage; \
		mkdir -p $$$$stage; \
		sed '1,/^$$$$/d' $(CURDIR)/tmp/manual/$1/doc/src/manual/$1_app.asciidoc \
			| sed -e "s|link:man:cowboy(7)|$$$${man7_cowboy:-link:cowboy_app}|g" \
				-e "s|link:man:cowlib(7)|$$$${man7_cowlib:-link:cowlib_app}|g" \
				-e "s|link:man:gun(7)|$$$${man7_gun:-link:gun_app}|g" \
				-e "s|link:man:ranch(7)|$$$${man7_ranch:-link:ranch_app}|g" \
			| sed 's/\(link:man:[a-z0-9_]*\):/\1./g' \
			| sed $$$$man3sed \
			| sed 's/link:man:\([a-z0-9_.]*\)[1-9()]*/link:\1/g' \
			| otp_links \
			| $$$$asciidoc --no-header-footer --safe - \
			> $(CURDIR)/tmp/$1-index.html; \
		wrap "$2 Function Reference" $(CURDIR)/tmp/$1-index.html $$$$stage/index.html $$$$version; \
		for f in $(CURDIR)/tmp/manual/$1/doc/src/manual/*.asciidoc; do \
			base=$$$$(basename "$$$$f" .asciidoc); \
			title=$$$$(sed -n '1,/^= .*/ s/^= //p' "$$$$f"); \
			sed '1,/^$$$$/d' "$$$$f" \
				| sed -e "s|link:man:cowboy(7)|$$$${man7_cowboy:-link:..}|g" \
					-e "s|link:man:cowlib(7)|$$$${man7_cowlib:-link:..}|g" \
					-e "s|link:man:gun(7)|$$$${man7_gun:-link:..}|g" \
					-e "s|link:man:ranch(7)|$$$${man7_ranch:-link:..}|g" \
				| sed 's/\(link:man:[a-z0-9_]*\):/\1./g' \
				| sed $$$$man3sed \
				| sed 's/link:man:\([a-z0-9_.]*\)[1-9()]*/link:..\/\1/g' \
				| otp_links \
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
	$(call docs-man-links,$1); \
	i=1; \
	for version in $$$$versions; do \
		branch=$$$$(echo $$$$branches | cut -d' ' -f $$$$i); \
		i=$$$$((i + 1)); \
		git -C $(CURDIR)/tmp/guide/$1 checkout -f $$$$branch; \
		git -C $(CURDIR)/tmp/guide/$1 reset --hard $$$$branch; \
		mf=$(CURDIR)/tmp/guide/$1/Makefile; \
		man_links; \
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
				| sed -e "s|link:man:cowboy(7)|$$$${man7_cowboy:-link:/docs/en/cowboy/$$$$version/manual/}|g" \
					-e "s|link:man:cowlib(7)|$$$${man7_cowlib:-link:/docs/en/cowlib/$$$$version/manual/}|g" \
					-e "s|link:man:gun(7)|$$$${man7_gun:-link:/docs/en/gun/$$$$version/manual/}|g" \
					-e "s|link:man:ranch(7)|$$$${man7_ranch:-link:/docs/en/ranch/$$$$version/manual/}|g" \
				| sed 's/\(link:man:[a-z0-9_]*\):/\1./g' \
				| sed $$$$man3sed \
				| sed 's/link:man:\([a-z0-9_.]*\)[1-9()]*/link:\/docs\/en\/$1\/'"$$$$version"'\/manual\/\1/g' \
				| otp_links \
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
