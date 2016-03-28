-module(tictactoe).

-export([new/0]).
-export([play/4]).
-export([check/1]).

new() ->
    {undefined, undefined, undefined,
     undefined, undefined, undefined,
     undefined, undefined, undefined}.

play(Who, X, Y, Board) ->
    setelement((Y - 1) * 3 + X, Board, Who).

check(Board) ->
    case Board of
        {x, x, x,
         _, _, _,
         _, _, _} -> {victory, x};

        {_, _, _,
         x, x, x,
         _, _, _} -> {victory, x};

        {_, _, _,
         _, _, _,
         x, x, x} -> {victory, x};

        {x, _, _,
         x, _, _,
         x, _, _} -> {victory, x};

        {_, x, _,
         _, x, _,
         _, x, _} -> {victory, x};

        {_, _, x,
         _, _, x,
         _, _, x} -> {victory, x};

        {x, _, _,
         _, x, _,
         _, _, x} -> {victory, x};

        {_, _, x,
         _, x, _,
         x, _, _} -> {victory, x};

        {o, o, o,
         _, _, _,
         _, _, _} -> {victory, o};

        {_, _, _,
         o, o, o,
         _, _, _} -> {victory, o};

        {_, _, _,
         _, _, _,
         o, o, o} -> {victory, o};

        {o, _, _,
         o, _, _,
         o, _, _} -> {victory, o};

        {_, o, _,
         _, o, _,
         _, o, _} -> {victory, o};

        {_, _, o,
         _, _, o,
         _, _, o} -> {victory, o};

        {o, _, _,
         _, o, _,
         _, _, o} -> {victory, o};

        {_, _, o,
         _, o, _,
         o, _, _} -> {victory, o};

        {A, B, C,
         D, E, F,
         G, H, I} when A =/= undefined, B =/= undefined, C =/= undefined,
                       D =/= undefined, E =/= undefined, F =/= undefined,
                       G =/= undefined, H =/= undefined, I =/= undefined ->
            draw;

        _ -> ok
    end.
