-module(ninenines).

-export([build/0]).
-export([run/0]).
-export([execute/2]).

%% Generate the website.

build() ->
	ok = application:start(yamerl),
	[Articles] = clean(yamerl:decode_file("../_data/articles.conf")),
	[Projects] = clean(yamerl:decode_file("../_data/projects.conf")),
	[Talks] = clean(yamerl:decode_file("../_data/talks.conf")),
	io:format("~p~n~p~n~p~n", [Articles, Projects, Talks]),
	pages:build(Articles, Projects, Talks),
	docs:build(Projects),
	%% @todo feeds:build(Articles, Talks),
	ok.

clean(Data) ->
	clean(Data, []).

clean([], Acc) ->
	lists:reverse(Acc);
clean([L|Tail], Acc) when is_list(L) ->
	clean(Tail, [clean(L)|Acc]);
clean([{"date", Date}|Tail], Acc) ->
	Date2 = {Date div 10000, Date div 100 rem 100, Date rem 100},
	clean(Tail, [{date, Date2}|Acc]);
clean([{Key, Value=[[E|_]|_]}|Tail], Acc) when is_tuple(E) ->
	clean(Tail, [{list_to_atom(Key), clean(Value)}|Acc]);
clean([{Key, Value}|Tail], Acc) ->
	clean(Tail, [{list_to_atom(Key), Value}|Acc]).

%% Start Cowboy for testing the generated website.

run() ->
	application:start(crypto),
	application:start(ranch),
	application:start(cowlib),
	application:start(cowboy),
	{ok, _} = cowboy:start_http(ninenines, 10, [{port, 9999}],
		[
			{middlewares, [ninenines, cowboy_router, cowboy_handler]},
			{env, [{dispatch, cowboy_router:compile([{'_', [
				{"/[...]", cowboy_static, {dir, "../"}}
			]}])}]}
		]),
	io:format("Test URL: http://localhost:9999/~n"),
	receive after 3600 -> ok end.

execute(Req, Env) ->
	Path = case cowboy_req:get(path, Req) of
		<<>> -> <<"/index.html">>;
		P ->
			case filelib:is_dir(<< "..", P/binary >>) of
				true -> << P/binary, "/index.html" >>;
				_ -> P
			end
	end,
	{ok, cowboy_req:set([{path, Path}], Req), Env}.
