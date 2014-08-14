-module(pages).

-export([build/3]).
-export([write/2]).

build(Articles, Projects, Talks) ->
	article_list(Articles),
	articles(Articles),
	support(Projects),
	talks(Talks),
	toppage(Projects),
	training(),
	ok.

write(Path, Page) ->
	filelib:ensure_dir(Path),
	ok = file:write_file(Path, unicode:characters_to_binary(Page)).

%% Articles.

article_list(Articles) ->
	{ok, Page} = article_list_dtl:render([
		{articles, Articles}
	]),
	write("../articles/index.html", Page).

articles(Articles) ->
	_ = [article(Articles, A) || A <- Articles],
	ok.

article(Articles,
		[{name, Name}, {date, Date},
		{title, Title}, {desc, _}]) ->
	{ok, Contents} = file:read_file(
		"../_data/articles/" ++ Name ++ ".html"),
	{ok, Page} = article_dtl:render([
		{title, Title},
		{date, Date},
		{contents, Contents},
		{articles, Articles}
	]),
	write("../articles/" ++ Name ++ "/index.html", Page).

%% Support.

support(Projects) ->
	{ok, Page} = support_dtl:render([
		{projects, Projects}
	]),
	write("../support/index.html", Page).

%% Talks.

talks(Talks) ->
	{ok, Page} = talks_dtl:render([
		{talks, Talks}
	]),
	write("../talks/index.html", Page).

%% Toppage.

toppage(Projects) ->
	{ok, Page} = toppage_dtl:render([
		{projects, Projects}
	]),
	write("../index.html", Page).

%% Training.

training() ->
	{ok, Page} = training_dtl:render([]),
	write("../training/index.html", Page).
