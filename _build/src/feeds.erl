-module(feeds).

-export([build/2]).

build(Articles, Talks) ->
	E1 = [begin
		{_, Title} = lists:keyfind(title, 1, A),
		{_, Name} = lists:keyfind(name, 1, A),
		{_, Date} = lists:keyfind(date, 1, A),
		{_, Desc} = lists:keyfind(desc, 1, A),
		{Title, "/articles/" ++ Name, Date, Desc}
	end || A <- Articles],
	{_, UpcomingTalks} = lists:keyfind(upcoming, 1, Talks),
	E2 = [begin
		{_, Title} = lists:keyfind(title, 1, T),
		{_, Link} = lists:keyfind(link, 1, T),
		{_, Date} = lists:keyfind(date, 1, T),
		{_, Name} = lists:keyfind(name, 1, T),
		{Title, Link, Date, "Conference: " ++ Name}
	end || T <- UpcomingTalks],
	E3 = lists:reverse(lists:keysort(3, E1 ++ E2)),
	{Entries, _} = lists:split(3, [[
		{title, Title},
		{link, Link},
		{updated, Updated},
		{summary, Summary}
	] || {Title, Link, Updated = {Y, _, _}, Summary} <- E3, Y < 3000]),
	[Last|_] = Entries,
	{_, Updated} = lists:keyfind(updated, 1, Last),
	{ok, Xml} = atom_dtl:render([
		{updated, Updated},
		{entries, Entries}
	]),
	pages:write("../feeds/atom.xml", Xml).
