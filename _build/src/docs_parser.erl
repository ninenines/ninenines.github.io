-module(docs_parser).
-export([convert/2]).

convert(DocumentBin, Path) ->
	Lines = binary:split(DocumentBin, <<"\n">>, [global]),
	[no_context(Lines, Path, []), "</div>\n"].

no_context([], _, Acc) ->
	iolist_to_binary(lists:reverse(Acc));
no_context([<<>>|Tail], Path, Acc) ->
	no_context(Tail, Path, Acc);
no_context([<<"* * *">>|Tail], Path, Acc) ->
	no_context(Tail, Path, [separator()|Acc]);
no_context(Quote = [<<"> ", _/binary>>|_], Path, Acc) ->
	quote(Quote, Path, Acc, []);
no_context([<<"```">>|Tail], Path, Acc) ->
	block(Tail, Path, Acc, <<"plain">>, []);
no_context([<<"``` Makefile">>|Tail], Path, Acc) ->
	block(Tail, Path, Acc, <<"plain">>, []);
no_context([<<"``` ", Language/binary>>|Tail], Path, Acc) ->
	block(Tail, Path, Acc, Language, []);
no_context([<<" *  ", Text/binary>>|Tail], Path, Acc) ->
	list1(Tail, Path, Acc, [inline(Text, Path)]);
no_context(Lines = [<<" -  ", _/binary>>|_], Path, Acc) ->
	dl(Lines, Path, Acc, []);
%% We ignore the separator line between th and tr here.
no_context([<<"| ", Header/binary>>, _|Tail], Path, Acc) ->
	th(Header, Tail, Path, Acc);
no_context([<<"### ", Spec/binary>>|Tail], Path, Acc) ->
	spec(Spec, Tail, Path, Acc);
no_context([Text|Tail], Path, Acc) ->
	text(Tail, Path, Acc, [inline(Text, Path)]).

quote([<<">  *  ", Text/binary>>|Tail], Path, Acc, QuoteAcc) ->
	quote_list(Tail, Path, Acc, QuoteAcc, [inline(Text, Path)]);
%% We ignore the separator line between th and tr here.
quote([<<"> | ", Header/binary>>, _|Tail], Path, Acc, QuoteAcc) ->
	quote_th(Header, Tail, Path, Acc, QuoteAcc);
quote([<<">">>|Tail], Path, Acc, QuoteAcc) ->
	quote(Tail, Path, Acc, ["<br/><br/>"|QuoteAcc]);
quote([<<">", Text/binary>>|Tail], Path, Acc, QuoteAcc) ->
	quote(Tail, Path, Acc, [inline(Text, Path)|QuoteAcc]);
quote(Lines, Path, Acc, QuoteAcc) ->
	no_context(Lines, Path, [blockquote(lists:reverse(QuoteAcc))|Acc]).

quote_list([<<">  *  ", Text/binary>>|Tail], Path, Acc, QuoteAcc, Items) ->
	quote_list(Tail, Path, Acc, QuoteAcc, [inline(Text, Path)|Items]);
quote_list([<<">">>|Tail], Path, Acc, QuoteAcc, Items) ->
	quote(Tail, Path, Acc, [make_list(Items)|QuoteAcc]);
quote_list(Lines = [<<">", _/binary>>|_], Path, Acc, QuoteAcc, Items) ->
	quote(Lines, Path, Acc, [make_list(Items)|QuoteAcc]);
quote_list(Lines, Path, Acc, QuoteAcc, Items) ->
	no_context(Lines, Path,
		[blockquote(lists:reverse([make_list(Items)|QuoteAcc]))|Acc]).

quote_th(HeaderBin, Lines, Path, Acc, QuoteAcc) ->
	Headers = binary:split(HeaderBin, <<"|">>, [trim, global]),
	quote_tr(Headers, Lines, Path, Acc, QuoteAcc, []).

quote_tr(Headers, [<<">">>|Tail], Path, Acc, QuoteAcc, RowsAcc) ->
	quote(Tail, Path, Acc, [table(Headers, lists:reverse(RowsAcc))|QuoteAcc]);
quote_tr(Headers, [<<>>|Tail], Path, Acc, QuoteAcc, RowsAcc) ->
	no_context(Tail, Path, [blockquote(lists:reverse(
		[table(Headers, lists:reverse(RowsAcc))|QuoteAcc]))|Acc]);
quote_tr(Headers, [<<"> | ", Row/binary>>|Tail], Path, Acc, QuoteAcc, RowsAcc) ->
	Cols = binary:split(Row, <<"|">>, [trim, global]),
	Cols2 = case length(Cols) of
		2 -> Cols;
		_ ->
			[H|T] = Cols,
			T2 = [binary_to_list(S) || S <- T],
			[H, iolist_to_binary(string:join(T2, " | "))]
	end,
	Cols3 = [inline(Text, Path) || Text <- Cols2],
	quote_tr(Headers, Tail, Path, Acc, QuoteAcc, [table_row(Cols3)|RowsAcc]).

block([<<"```">>|Tail], Path, Acc, Language, BlockAcc) ->
	no_context(Tail, Path, [block(lists:reverse(BlockAcc), Language)|Acc]);
block([Text|Tail], Path, Acc, Language, BlockAcc) ->
	block(Tail, Path, Acc, Language, [<<"\n">>, Text|BlockAcc]).

list1([<<>>|Tail], Path, Acc, Items) ->
	no_context(Tail, Path, [make_list(Items)|Acc]);
list1([<<" *  ", Text/binary>>|Tail], Path, Acc, Items) ->
	list1(Tail, Path, Acc, [inline(Text, Path)|Items]);
list1([<<"   *  ", Text/binary>>|Tail], Path, Acc, Items) ->
	list2(Tail, Path, Acc, Items, [inline(Text, Path)]).

list2([<<>>|Tail], Path, Acc, Items, SubItems) ->
	no_context(Tail, Path, [make_list([make_list(SubItems)|Items])|Acc]);
list2([<<" *  ", Text/binary>>|Tail], Path, Acc, Items, SubItems) ->
	list1(Tail, Path, Acc, [inline(Text, Path), make_list(SubItems)|Items]);
list2([<<"   *  ", Text/binary>>|Tail], Path, Acc, Items, SubItems) ->
	list2(Tail, Path, Acc, Items, [inline(Text, Path)|SubItems]).

make_list(Items) ->
	Items2 = [list_item(I) || I <- lists:reverse(Items)],
	list(Items2).

dl([<<" -  ", DT/binary>>, <<"   -  ", DD/binary>>|Tail], Path, Acc, Defs) ->
	dl(Tail, Path, Acc, [def(DT, DD)|Defs]);
dl(Lines, Path, Acc, Defs) ->
	no_context(Lines, Path, [def_block(lists:reverse(Defs))|Acc]).

th(HeaderBin, Lines, Path, Acc) ->
	Headers = binary:split(HeaderBin, <<"|">>, [trim, global]),
	tr(Headers, Lines, Path, Acc, []).

tr(Headers, Tail=[], Path, Acc, RowsAcc) ->
	no_context(Tail, Path, [table(Headers, lists:reverse(RowsAcc))|Acc]);
tr(Headers, [<<>>|Tail], Path, Acc, RowsAcc) ->
	no_context(Tail, Path, [table(Headers, lists:reverse(RowsAcc))|Acc]);
tr(Headers, [<<"| ", Row/binary>>|Tail], Path, Acc, RowsAcc) ->
	Cols = binary:split(Row, <<"|">>, [trim, global]),
	Cols2 = [inline(Text, Path) || Text <- Cols],
	tr(Headers, Tail, Path, Acc, [table_row(Cols2)|RowsAcc]).

spec(Spec, [<<>>|Tail], Path, Acc) ->
	no_context(Tail, Path, [spec(Spec)|Acc]);
spec(Spec, [<<"### ", NewSpec/binary>>|Tail], Path, Acc) ->
	spec(NewSpec, Tail, Path, [spec(Spec)|Acc]);
spec(Spec, [Line|Tail], Path, Acc) ->
	spec(<< Spec/binary, Line/binary >>, Tail, Path, Acc).

text([<<>>|Tail], Path, Acc, TextAcc) ->
	no_context(Tail, Path, [text(lists:reverse(TextAcc))|Acc]);
text([<<"====", _/binary>>, <<>>|Tail], Path, Acc, [Title]) ->
	no_context(Tail, Path, [title1(Title)|Acc]);
text([<<"----", _/binary>>, <<>>|Tail], Path, Acc, [Title]) ->
	no_context(Tail, Path, [title2(Title)|Acc]);
text([<<" *  ", Text/binary>>|Tail], Path, Acc, TextAcc) ->
	list1(Tail, Path, [text(lists:reverse(TextAcc))|Acc], [inline(Text, Path)]);
text([Text|Tail], Path, Acc, TextAcc) ->
	text(Tail, Path, Acc, [inline(Text, Path), " "|TextAcc]).

blockquote(Text) ->
	["<blockquote>", Text, "</blockquote>\n"].

separator() ->
	"<hr/>".

block(Text, <<>>) ->
	["<script type=\"syntaxhighlighter\"><![CDATA[\n",
		Text, "]]></script>\n"];
block(Text, Language) ->
	["<script type=\"syntaxhighlighter\" class=\"brush: ",
		Language, "\"><![CDATA[\n", Text, "]]></script>\n"].

list(Items) ->
	Items2 = iolist_to_binary(Items),
	Items3 = binary:replace(Items2, <<"</li>\n<li><ul>">>, <<"\n<ul>">>, [global]),
	["<ul>\n", Items3, "</ul>\n"].

list_item(Text) ->
	["<li>", Text, "</li>\n"].

def(DT, DD) ->
	["<dt>", DT, "</dt><dd>", DD, "</dd>"].

def_block(Defs) ->
	["<dl>", Defs, "</dl>"].

table(Cols, Rows) ->
	["<table class=\"table-bordered table-condensed table-striped\"><thead><tr>",
		[["<th>", H, "</th>"] || H <- Cols],
		"</tr></thead><tbody>", Rows, "</tbody></table>"].

table_row(Cols) ->
	["<tr>", [["<td>", C, "</td>"] || C <- Cols], "</tr>"].

text(Text) ->
	["<p>", Text, "</p>\n"].

title1(Text) ->
	["<h1 class=\"lined-header\"><span>", Text, "</span></h1>\n",
		"<div class=\"service-description\">\n"].

title2(Text) ->
	["<h2>", Text, "</h2>\n"].

spec(Text) ->
	["<h4>", Text, "</h4>\n"].

inline(Text, Path) ->
	Text2 = re:replace(Text, "`(.+?)`",
		"<code>\\1</code>", [global]),
	Text3 = re:replace(Text2, "!\\[(.+?)\\]\\((.+?)\\)",
		"<img alt=\"\\1\" src=\"" ++ Path ++ "\\2\"/>", [global]),
	Text4 = re:replace(Text3, "\\[(.+?)\\]\\((.+?)\\.md\\)",
		"<a href=\"" ++ Path ++ "\\2\">\\1</a>", [global]),
	Text5 = re:replace(Text4, "\\[(.+?)\\]\\((.+?)\\)",
		"<a href=\"\\2\">\\1</a>", [global]),
	Text6 = re:replace(Text5, "\\*\\*(.+?)\\*\\*",
		"<strong>\\1</strong>", [global]),
	Text6.
