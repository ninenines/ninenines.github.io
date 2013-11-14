-module(docs).
-export([build/1]).

build(Projects) ->
	_ = [project(P) || P <- Projects],
	ok.

project(P) ->
	{_, Name} = lists:keyfind(name, 1, P),
	{_, Title} = lists:keyfind(title, 1, P),
	io:format("Building project: ~s~n", [Name]),
	guide(Name, Title),
	manual(Name, Title),
	readme(Name, Title),
	io:format("Done.~n"),
	ok.

%% Guide and manual.

guide(P, T) ->
	io:format("  ~s: guide~n", [P]),
	build_dir(P, T, guide, "/guide/").

manual(P, T) ->
	io:format("  ~s: manual~n", [P]),
	build_dir(P, T, manual, "/manual/").

build_dir(P, T, Type, Suffix) ->
	Path = "deps/" ++ P ++ Suffix,
	case file:list_dir(Path) of
		{ok, Filenames} ->
			[build_file(Path ++ F, P, T, Type, F, Suffix) || F <- Filenames];
		{error, enoent} ->
			ok
	end.

build_file(Filename, P, T, Type, F, Suffix) ->
	case filename:extension(Filename) of
		".md" ->
			io:format("  ~s: down ~s~n", [P, Filename]),
			{ok, Data} = file:read_file(Filename),
			OutPath = "../docs/en/" ++ P ++ "/HEAD" ++ Suffix,
			Html = docs_parser:convert(Data,
				"/docs/en/" ++ P ++ "/HEAD" ++ Suffix),
			{ok, Body} = docs_dtl:render([
				{contents, Html},
				{type, Type},
				{toc, ""},
				{project, T}
			]),
			case filename:basename(F, ".md") of
				"toc" ->
					filelib:ensure_dir(OutPath),
					file:write_file(OutPath ++ "index.html", Body);
				_ ->
					filelib:ensure_dir(OutPath ++ filename:rootname(F) ++ "/"),
					file:write_file(OutPath ++ filename:rootname(F)
						++ "/index.html", Body)
			end;
		_ ->
			OutPath = "../docs/en/" ++ P ++ "/HEAD" ++ Suffix,
			{ok, _} = file:copy(Filename, OutPath ++ F),
			ok
	end.

%% README.

readme(P, T) ->
	io:format("  ~s: readme~n", [P]),
	Path = "deps/" ++ P ++ "/README.md",
	{ok, Data} = file:read_file(Path),
	OutPath = "../docs/en/" ++ P ++ "/HEAD/index.html",
	Html = docs_parser:convert(Data,
		"/docs/en/" ++ P ++ "/HEAD/"),
	{ok, Body} = docs_dtl:render([
		{contents, Html},
		{type, readme},
		{toc, <<>>},
		{project, T}
	]),
	filelib:ensure_dir(OutPath),
	file:write_file(OutPath, Body).
