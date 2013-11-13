-module(docs_parser).
-export([convert/1]).

convert(DocumentBin) ->
	Lines = binary:split(DocumentBin, <<"\n">>, [global]),
	[no_context(Lines, []), "</div>\n"].

no_context([], Acc) ->
	iolist_to_binary(lists:reverse(Acc));
no_context([<<>>|Tail], Acc) ->
	no_context(Tail, Acc);
no_context([<<"* * *">>|Tail], Acc) ->
	no_context(Tail, [separator()|Acc]);
no_context(Quote = [<<"> ", _/binary>>|_], Acc) ->
	quote(Quote, Acc, []);
no_context([<<"```">>|Tail], Acc) ->
	block(Tail, Acc, <<"plain">>, []);
no_context([<<"``` Makefile">>|Tail], Acc) ->
	block(Tail, Acc, <<"plain">>, []);
no_context([<<"``` ", Language/binary>>|Tail], Acc) ->
	block(Tail, Acc, Language, []);
no_context([<<" *  ", Text/binary>>|Tail], Acc) ->
	list1(Tail, Acc, [inline(Text)]);
no_context(Lines = [<<" -  ", _/binary>>|_], Acc) ->
	dl(Lines, Acc, []);
%% We ignore the separator line between th and tr here.
no_context([<<"| ", Header/binary>>, _|Tail], Acc) ->
	th(Header, Tail, Acc);
no_context([<<"### ", Spec/binary>>|Tail], Acc) ->
	spec(Spec, Tail, Acc);
no_context([Text|Tail], Acc) ->
	text(Tail, Acc, [inline(Text)]).

quote([<<">  *  ", Text/binary>>|Tail], Acc, QuoteAcc) ->
	quote_list(Tail, Acc, QuoteAcc, [inline(Text)]);
%% We ignore the separator line between th and tr here.
quote([<<"> | ", Header/binary>>, _|Tail], Acc, QuoteAcc) ->
	quote_th(Header, Tail, Acc, QuoteAcc);
quote([<<">">>|Tail], Acc, QuoteAcc) ->
	quote(Tail, Acc, ["<br/><br/>"|QuoteAcc]);
quote([<<">", Text/binary>>|Tail], Acc, QuoteAcc) ->
	quote(Tail, Acc, [inline(Text)|QuoteAcc]);
quote(Lines, Acc, QuoteAcc) ->
	no_context(Lines, [blockquote(lists:reverse(QuoteAcc))|Acc]).

quote_list([<<">  *  ", Text/binary>>|Tail], Acc, QuoteAcc, Items) ->
	quote_list(Tail, Acc, QuoteAcc, [inline(Text)|Items]);
quote_list([<<">">>|Tail], Acc, QuoteAcc, Items) ->
	quote(Tail, Acc, [make_list(Items)|QuoteAcc]);
quote_list(Lines = [<<">", _/binary>>|_], Acc, QuoteAcc, Items) ->
	quote(Lines, Acc, [make_list(Items)|QuoteAcc]);
quote_list(Lines, Acc, QuoteAcc, Items) ->
	no_context(Lines,
		[blockquote(lists:reverse([make_list(Items)|QuoteAcc]))|Acc]).

quote_th(HeaderBin, Lines, Acc, QuoteAcc) ->
	Headers = binary:split(HeaderBin, <<"|">>, [trim, global]),
	quote_tr(Headers, Lines, Acc, QuoteAcc, []).

quote_tr(Headers, [<<">">>|Tail], Acc, QuoteAcc, RowsAcc) ->
	quote(Tail, Acc, [table(Headers, lists:reverse(RowsAcc))|QuoteAcc]);
quote_tr(Headers, [<<>>|Tail], Acc, QuoteAcc, RowsAcc) ->
	no_context(Tail, [blockquote(lists:reverse(
		[table(Headers, lists:reverse(RowsAcc))|QuoteAcc]))|Acc]);
quote_tr(Headers, [<<"> | ", Row/binary>>|Tail], Acc, QuoteAcc, RowsAcc) ->
	Cols = binary:split(Row, <<"|">>, [trim, global]),
	Cols2 = case length(Cols) of
		2 -> Cols;
		_ ->
			[H|T] = Cols,
			T2 = [binary_to_list(S) || S <- T],
			[H, iolist_to_binary(string:join(T2, " | "))]
	end,
	Cols3 = [inline(Text) || Text <- Cols2],
	quote_tr(Headers, Tail, Acc, QuoteAcc, [table_row(Cols3)|RowsAcc]).

block([<<"```">>|Tail], Acc, Language, BlockAcc) ->
	no_context(Tail, [block(lists:reverse(BlockAcc), Language)|Acc]);
block([Text|Tail], Acc, Language, BlockAcc) ->
	block(Tail, Acc, Language, [<<"\n">>, Text|BlockAcc]).

list1([<<>>|Tail], Acc, Items) ->
	no_context(Tail, [make_list(Items)|Acc]);
list1([<<" *  ", Text/binary>>|Tail], Acc, Items) ->
	list1(Tail, Acc, [inline(Text)|Items]);
list1([<<"   *  ", Text/binary>>|Tail], Acc, Items) ->
	list2(Tail, Acc, Items, [inline(Text)]).

list2([<<>>|Tail], Acc, Items, SubItems) ->
	no_context(Tail, [make_list([make_list(SubItems)|Items])|Acc]);
list2([<<" *  ", Text/binary>>|Tail], Acc, Items, SubItems) ->
	list1(Tail, Acc, [inline(Text), make_list(SubItems)|Items]);
list2([<<"   *  ", Text/binary>>|Tail], Acc, Items, SubItems) ->
	list2(Tail, Acc, Items, [inline(Text)|SubItems]).

make_list(Items) ->
	Items2 = [list_item(I) || I <- lists:reverse(Items)],
	list(Items2).

dl([<<" -  ", DT/binary>>, <<"   -  ", DD/binary>>|Tail], Acc, Defs) ->
	dl(Tail, Acc, [def(DT, DD)|Defs]);
dl(Lines, Acc, Defs) ->
	no_context(Lines, [def_block(lists:reverse(Defs))|Acc]).

th(HeaderBin, Lines, Acc) ->
	Headers = binary:split(HeaderBin, <<"|">>, [trim, global]),
	tr(Headers, Lines, Acc, []).

tr(Headers, Tail=[], Acc, RowsAcc) ->
	no_context(Tail, [table(Headers, lists:reverse(RowsAcc))|Acc]);
tr(Headers, [<<>>|Tail], Acc, RowsAcc) ->
	no_context(Tail, [table(Headers, lists:reverse(RowsAcc))|Acc]);
tr(Headers, [<<"| ", Row/binary>>|Tail], Acc, RowsAcc) ->
	Cols = binary:split(Row, <<"|">>, [trim, global]),
	Cols2 = [inline(Text) || Text <- Cols],
	tr(Headers, Tail, Acc, [table_row(Cols2)|RowsAcc]).

spec(Spec, [<<>>|Tail], Acc) ->
	no_context(Tail, [spec(Spec)|Acc]);
spec(Spec, [<<"### ", NewSpec/binary>>|Tail], Acc) ->
	spec(NewSpec, Tail, [spec(Spec)|Acc]);
spec(Spec, [Line|Tail], Acc) ->
	spec(<< Spec/binary, Line/binary >>, Tail, Acc).

text([<<>>|Tail], Acc, TextAcc) ->
	no_context(Tail, [text(lists:reverse(TextAcc))|Acc]);
text([<<"====", _/binary>>, <<>>|Tail], Acc, [Title]) ->
	no_context(Tail, [title1(Title)|Acc]);
text([<<"----", _/binary>>, <<>>|Tail], Acc, [Title]) ->
	no_context(Tail, [title2(Title)|Acc]);
text([<<" *  ", Text/binary>>|Tail], Acc, TextAcc) ->
	list1(Tail, [text(lists:reverse(TextAcc))|Acc], [inline(Text)]);
text([Text|Tail], Acc, TextAcc) ->
	text(Tail, Acc, [inline(Text), " "|TextAcc]).

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

inline(Text) ->
	Text2 = re:replace(Text, "`(.+?)`",
		"<code>\\1</code>", [global]),
	Text3 = re:replace(Text2, "!\\[(.+?)\\]\\((.+?)\\)",
		"<img alt=\"\\1\" src=\"\\2\"/>", [global]),
	Text4 = re:replace(Text3, "\\[(.+?)\\]\\((.+?)\\.md\\)",
		"<a href=\"\\2\">\\1</a>", [global]),
	Text5 = re:replace(Text4, "\\[(.+?)\\]\\((.+?)\\)",
		"<a href=\"\\2\">\\1</a>", [global]),
	Text6 = re:replace(Text5, "\\*\\*(.+?)\\*\\*",
		"<strong>\\1</strong>", [global]),
	Text6.
