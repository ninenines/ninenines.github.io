PROJECT = ninenines

DEPS = cowboy ranch bullet sheriff erlydtl ezdoc yamerl
dep_cowboy = git https://github.com/ninenines/cowboy master
dep_ranch = git https://github.com/ninenines/ranch master
dep_bullet = git https://github.com/extend/bullet master
dep_sheriff = git https://github.com/extend/sheriff master
dep_erlydtl = git https://github.com/evanmiller/erlydtl 4d0dc8fb
dep_ezdoc = git https://github.com/ninenines/ezdoc master
dep_yamerl = git https://github.com/yakaz/yamerl 261da0ee

.PHONY: build clean-build run

build: clean-build deps/erlang.mk all
	@erl -pa ebin deps/*/ebin -noshell -eval 'ninenines:build(), init:stop().'

clean-build:
	@rm -rf ../index.html ../articles/ ../docs/ ../feeds/ ../support/ \
		../talks/index.html ../training/

deps/erlang.mk:
	git clone https://github.com/extend/erlang.mk deps/erlang.mk

run:
	@erl -pa ebin deps/*/ebin -noshell -eval 'ninenines:run().'

include erlang.mk
