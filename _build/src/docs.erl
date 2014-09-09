-module(docs).
-export([build/1]).

build(Projects) ->
	_ = [project(P) || P <- Projects],
	{ok, SpecsDB} = file:read_file("../docs/db.json.tmp"),
	S = byte_size(SpecsDB) - 1,
	<< SpecsDB2:S/binary, _/bits >> = SpecsDB,
	ok = file:write_file("../docs/db.json", ["[", SpecsDB2, "]"]),
	ok = file:delete("../docs/db.json.tmp").

project(P) ->
	{_, Name} = lists:keyfind(name, 1, P),
	{_, Title} = lists:keyfind(title, 1, P),
	{_, Versions} = lists:keyfind(versions, 1, P),
	{_, Tags} = lists:keyfind(tags, 1, P),
	VT = lists:zip(Versions, Tags),
	[begin
		io:format("Building project: ~s/~s~n", [Name, V]),
		os:cmd("cd deps/" ++ Name ++ " && git checkout " ++ T),
		guide(P, Name, Title, V),
		manual(P, Name, Title, V),
		readme(P, Name, Title, V),
		io:format("Done.~n")
	end || {V, T} <- VT],
	ok.

%% Guide and manual.

guide(P, N, T, V) ->
	io:format("  ~s: guide~n", [N]),
	build_dir(P, N, T, V, guide, "/doc/src/guide/", "/guide/"),
	build_dir(P, N, T, V, guide, "/guide/", "/guide/").

manual(P, N, T, V) ->
	io:format("  ~s: manual~n", [N]),
	build_dir(P, N, T, V, manual, "/doc/src/manual/", "/manual/"),
	build_dir(P, N, T, V, manual, "/manual/", "/manual/").

build_dir(P, N, T, V, Type, Location, Suffix) ->
	Path = "deps/" ++ N ++ Location,
	case file:list_dir(Path) of
		{ok, Filenames} ->
			[build_file(Path ++ F, P, N, T, V, Type, F, Suffix) || F <- Filenames];
		{error, enoent} ->
			ok
	end.

build_file(Filename, P, N, T, V, Type, F, Suffix) ->
	{_, Versions} = lists:keyfind(versions, 1, P),
	Prefix = "/docs/en/" ++ N ++ "/",
	case filename:extension(Filename) of
		".ezdoc" ->
			io:format("  ~s: ezdoc ~s~n", [N, Filename]),
			OutPath = "../docs/en/" ++ N ++ "/" ++ V ++ Suffix,
			put(path, "/docs/en/" ++ N ++ "/" ++ V ++ Suffix),
			{ok, Body} = docs_dtl:render([
				{contents, docs_html:export(ezdoc:parse_file(Filename))},
				{type, Type},
				{see_also, see_also(Type, P, N, V)},
				{versions, Versions},
				{prefix, Prefix},
				{suffix, Suffix},
				{project, T}
			]),
			case filename:basename(F, ".ezdoc") of
				"index" ->
					OutPath2 = OutPath ++ "index.html",
					filelib:ensure_dir(OutPath2),
					ok = file:write_file(OutPath2, Body);
				_ ->
					OutPath2 = OutPath ++ filename:rootname(F) ++ "/index.html",
					filelib:ensure_dir(OutPath2),
					ok = file:write_file(OutPath2, Body),
					specs_db(filename:rootname(F),
						"/docs/en/" ++ N ++ "/" ++ V ++ Suffix
							++ filename:rootname(F) ++ "/index.html")
			end;
		".md" ->
			io:format("  ~s: down ~s~n", [N, Filename]),
			{ok, Data} = file:read_file(Filename),
			OutPath = "../docs/en/" ++ N ++ "/" ++ V ++ Suffix,
			Html = docs_parser:convert(Data,
				"/docs/en/" ++ N ++ "/" ++ V ++ Suffix),
			{ok, Body} = docs_dtl:render([
				{contents, Html},
				{type, Type},
				{see_also, see_also(Type, P, N, V)},
				{versions, Versions},
				{prefix, Prefix},
				{suffix, Suffix},
				{project, T}
			]),
			case filename:basename(F, ".md") of
				"toc" ->
					OutPath2 = OutPath ++ "index.html",
					filelib:ensure_dir(OutPath2),
					ok = file:write_file(OutPath2, Body);
				_ ->
					OutPath2 = OutPath ++ filename:rootname(F) ++ "/index.html",
					filelib:ensure_dir(OutPath2),
					ok = file:write_file(OutPath2, Body),
					specs_db(filename:rootname(F),
						"/docs/en/" ++ N ++ "/" ++ V ++ Suffix
							++ filename:rootname(F) ++ "/index.html")
			end;
		_ ->
			OutPath = "../docs/en/" ++ N ++ "/" ++ V ++ Suffix,
			{ok, _} = file:copy(Filename, OutPath ++ F),
			ok
	end.

specs_db(M, L) ->
	Dict = erase(),
	J = ["{\"n\":\"" ++ M ++ ":" ++ binary_to_list(N) ++ "\",\"l\":\""
		++ L ++ "#" ++ binary_to_list(cowboy_bstr:to_lower(N)) ++ "\"},"
		|| {N, specs_db} <- Dict],
	ok = file:write_file("../docs/db.json.tmp", J, [append]),
	ok.

%% README.

readme(P, N, T, V) ->
	io:format("  ~s: readme~n", [N]),
	{_, Versions} = lists:keyfind(versions, 1, P),
	Path = "deps/" ++ N ++ "/README.md",
	{ok, Data} = file:read_file(Path),
	OutPath = "../docs/en/" ++ N ++ "/" ++ V ++ "/index.html",
	Prefix = "/docs/en/" ++ N ++ "/",
	Html = docs_parser:convert(Data,
		"/docs/en/" ++ N ++ "/" ++ V ++ "/"),
	{ok, Body} = docs_dtl:render([
		{contents, Html},
		{type, readme},
		{see_also, see_also(readme, P, N, V)},
		{versions, Versions},
		{prefix, Prefix},
		{suffix, <<"">>},
		{project, T}
	]),
	filelib:ensure_dir(OutPath),
	ok = file:write_file(OutPath, Body).

%% Resource select.

see_also(Type, P, N, V) ->
	{_, HasGuide} = lists:keyfind(guide, 1, P),
	{_, HasManual} = lists:keyfind(manual, 1, P),
	if
		not HasGuide, not HasManual ->
			"";
		true ->
			SeeGuide = if
				HasGuide, Type =/= guide ->
					"<li><a href=\"/docs/en/" ++ N
						++ "/" ++ V ++ "/guide/\">User Guide</a></li>";
				true ->
					""
			end,
			SeeManual = if
				HasManual, Type =/= manual ->
					"<li><a href=\"/docs/en/" ++ N
						++ "/" ++ V ++ "/manual/\">Function Reference</a></li>";
				true ->
					""
			end,
			SeeReadme = if
				Type =/= readme ->
					"<li><a href=\"/docs/en/" ++ N
						++ "/" ++ V ++ "/index.html\">README</a></li>";
				true ->
					""
			end,
			"<h3>See also</h3><ul>"
				++ SeeGuide ++ SeeManual ++ SeeReadme ++ "</ul>"
	end.
