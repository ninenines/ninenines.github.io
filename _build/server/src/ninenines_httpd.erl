-module(ninenines_httpd).

-export([serve/0]).
-export([execute/2]).

serve() ->
	{ok, _} = application:ensure_all_started(cowboy),
	DocRoot = docroot(),
	Dispatch = cowboy_router:compile([
		{'_', [
			{"/[...]", cowboy_static, {dir, DocRoot, [
				{mimetypes, cow_mimetypes, all},
				{charset, <<"utf-8">>}
			]}}
		]}
	]),
	{ok, _} = cowboy:start_clear(http, [{port, 8080}], #{
		env => #{dispatch => Dispatch, docroot => DocRoot},
		middlewares => [?MODULE, cowboy_router, cowboy_handler]
	}),
	io:format("Serving ~ts~nOpen http://localhost:8080/~n", [DocRoot]),
	ok.

%% Directories must keep their trailing slash. Relative links in the
%% manual are resolved against the request URL, and a missing slash
%% drops the manual/ segment.

execute(Req=#{path := Path}, Env=#{docroot := DocRoot}) ->
	case is_directory(DocRoot, Path) of
		true ->
			case binary:last(Path) of
				$/ ->
					{ok, Req#{path => <<Path/binary, "index.html">>}, Env};
				_ ->
					Location = cowboy_req:uri(Req, #{path => <<Path/binary, "/">>}),
					{stop, cowboy_req:reply(301, #{<<"location">> => Location}, Req)}
			end;
		false ->
			{ok, Req, Env}
	end.

docroot() ->
	Beam = code:which(?MODULE),
	ServerDir = filename:dirname(filename:dirname(Beam)),
	filename:absname(filename:join(ServerDir, "../..")).

is_directory(_DocRoot, Path) when Path =:= <<>> ->
	false;
is_directory(DocRoot, Path) ->
	case binary:match(Path, <<"..">>) of
		nomatch ->
			Rel = case Path of
				<<"/", Rest/binary>> -> Rest;
				_ -> Path
			end,
			Full = filename:join(DocRoot, binary_to_list(Rel)),
			filelib:is_dir(Full);
		_ ->
			false
	end.
