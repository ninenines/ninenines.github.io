PROJECT = ninenines_httpd
PROJECT_DESCRIPTION = Preview server for the Nine Nines website
PROJECT_VERSION = 0.1.0

DEPS = cowboy

include erlang.mk

serve: all
	$(verbose) $(ERL) -pa ebin/ deps/*/ebin -run ninenines_httpd serve
