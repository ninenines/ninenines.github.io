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
	io:format("Building project: ~s~n", [Name]),
	guide(P, Name, Title),
	manual(P, Name, Title),
	readme(P, Name, Title),
	io:format("Done.~n"),
	ok.

%% Guide and manual.

guide(P, N, T) ->
	io:format("  ~s: guide~n", [N]),
	build_dir(P, N, T, guide, "/guide/").

manual(P, N, T) ->
	io:format("  ~s: manual~n", [N]),
	build_dir(P, N, T, manual, "/manual/").

build_dir(P, N, T, Type, Suffix) ->
	Path = "deps/" ++ N ++ Suffix,
	case file:list_dir(Path) of
		{ok, Filenames} ->
			[build_file(Path ++ F, P, N, T, Type, F, Suffix) || F <- Filenames];
		{error, enoent} ->
			ok
	end.

build_file(Filename, P, N, T, Type, F, Suffix) ->
	case filename:extension(Filename) of
		".md" ->
			io:format("  ~s: down ~s~n", [N, Filename]),
			{ok, Data} = file:read_file(Filename),
			OutPath = "../docs/en/" ++ N ++ "/HEAD" ++ Suffix,
			Html = docs_parser:convert(Data,
				"/docs/en/" ++ N ++ "/HEAD" ++ Suffix),
			{ok, Body} = docs_dtl:render([
				{contents, Html},
				{type, Type},
				{see_also, see_also(Type, P, N)},
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
						"/docs/en/" ++ N ++ "/HEAD" ++ Suffix
							++ filename:rootname(F) ++ "/index.html")
			end;
		_ ->
			OutPath = "../docs/en/" ++ N ++ "/HEAD" ++ Suffix,
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

readme(P, N, T) ->
	io:format("  ~s: readme~n", [N]),
	Path = "deps/" ++ N ++ "/README.md",
	{ok, Data} = file:read_file(Path),
	OutPath = "../docs/en/" ++ N ++ "/HEAD/index.html",
	Html = docs_parser:convert(Data,
		"/docs/en/" ++ N ++ "/HEAD/"),
	{ok, Body} = docs_dtl:render([
		{contents, Html},
		{type, readme},
		{see_also, see_also(readme, P, N)},
		{project, T}
	]),
	filelib:ensure_dir(OutPath),
	ok = file:write_file(OutPath, Body).

%% Resource select.

see_also(Type, P, N) ->
	{_, HasGuide} = lists:keyfind(guide, 1, P),
	{_, HasManual} = lists:keyfind(manual, 1, P),
	if
		not HasGuide, not HasManual ->
			"";
		true ->
			SeeGuide = if
				HasGuide, Type =/= guide ->
					"<li><a href=\"/docs/en/" ++ N
						++ "/HEAD/guide/\">User Guide</a></li>";
				true ->
					""
			end,
			SeeManual = if
				HasManual, Type =/= manual ->
					"<li><a href=\"/docs/en/" ++ N
						++ "/HEAD/manual/\">Function Reference</a></li>";
				true ->
					""
			end,
			SeeReadme = if
				Type =/= readme ->
					"<li><a href=\"/docs/en/" ++ N
						++ "/HEAD/index.html\">README</a></li>";
				true ->
					""
			end,
			"<h3>See also</h3><ul>"
				++ SeeGuide ++ SeeManual ++ SeeReadme ++ "</ul>"
	end.
