%% Copyright (c) 2014, Loïc Hoguin <essen@ninenines.eu>
%%
%% Permission to use, copy, modify, and/or distribute this software for any
%% purpose with or without fee is hereby granted, provided that the above
%% copyright notice and this permission notice appear in all copies.
%%
%% THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
%% WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
%% MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
%% ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
%% WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
%% ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
%% OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

-module(docs_html).

-export([export/1]).

-spec export(ezdoc:ast()) -> iodata().
export(AST) ->
	export(AST, []).

export([], ["\n"|Acc]) ->
	lists:reverse(Acc);
export([Block|Tail], Acc) ->
	export(Tail, ["\n", block(Block)|Acc]).

block({h1, Text}) ->
	["<h1 class=\"lined-header\"><span>", inline(Text), "</span></h1>\n"];
block({h2, Text}) ->
	["<h2 id=\"",
		binary:replace(cowboy_bstr:to_lower(Text), <<" ">>, <<"_">>, [global]),
		"\">", inline(Text), "</h2>\n"];
block({h3, Text}) ->
	specs_db(Text),
	[Name|_] = binary:split(Text, <<"(">>),
	Name2 = cowboy_bstr:to_lower(Name),
	["<h3 id=\"", Name2, "\">", inline(Text), "</h3>\n"];
block({q, AST}) ->
	["<blockquote>", export(AST, []), "</blockquote>\n"];
block({cb, Language, Lines}) ->
	Language2 = case Language of
		<<"Makefile">> -> <<"plain">>;
		_ -> Language
	end,
	["<script type=\"syntaxhighlighter\" class=\"brush: ",
		Language2, "\"><![CDATA[\n",
		[[L, "\n"] || L <- Lines],
		"]]></script>\n"];
block({u, Items}) ->
	["<ul>\n", list(Items), "</ul>\n"];
block({t, Head, Rows}) ->
	["<table class=\"table-bordered table-condensed table-striped\">\n<thead>\n<tr>",
		[["<th>", inline(H), "</th>"] || {c, H} <- Head],
		"</tr>\n</thead>\n<tbody>\n",
		[["<tr>", [["<td>", inline(T), "</td>"] || {c, T} <- Cells], "</tr>\n"]
			|| {r, Cells} <- Rows],
		"</tbody>\n</table>\n"];
block({p, Text}) ->
	["<p>", inline(Text), "</p>\n"].

list([]) ->
	[];
list([{i, Item}, {u, List}|Tail]) ->
	["<li>", inline(Item), "<ul>\n", list(List), "</ul>\n</li>\n", list(Tail)];
list([{i, Item}|Tail]) ->
	["<li>", inline(Item), "</li>\n", list(Tail)].

inline(Text) when is_binary(Text) ->
	Text;
inline({e, Text}) ->
	["<em>", Text, "</em>"];
inline({ci, Text}) ->
	["<code>", Text, "</code>"];
inline({img, URL}) ->
	["<img src=\"", URL, "\"/>"];
inline({img, URL, Description}) ->
	["<img title=\"", Description, "\" src=\"", URL, "\"/>"];
inline({l, URL}) ->
	["<a href=\"", URL, "\">", URL, "</a>"];
inline({l, URL, Description}) ->
	["<a href=\"", URL, "\">", Description, "</a>"];
inline(Text) ->
	[inline(T) || T <- Text].

specs_db(Spec) ->
	[Name|_] = binary:split(Spec, <<"(">>),
	put(Name, specs_db).
