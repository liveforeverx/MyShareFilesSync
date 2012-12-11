-module(test).
-export([test/2, test2/2, test3/2, gen_values/2, perfomance/1, perfomance/0]).

%DBs = [a, b, c].
%[a,b,c]
%2> Data = [{t1, [va, vb, vc]}, {t2, ['va2', 'vb2', 'vc2']}].
%[{t1,[va,vb,vc]},{t2,[va2,vb2,vc2]}]

perfomance() ->
    perfomance([{3, 10}, {5, 40}, {10, 100}, {12, 2000}, {20, 50000}]).

perfomance(List) ->
    crypto:start(),
    perfomance(List, []).
perfomance([], Acc) ->
    Acc;
perfomance([{N1, N2} | Other], Acc) ->
    {DBs, Data} = gen_values(N1, N2),
    {Time, _} = timer:tc(test, test, [DBs, Data]),
    {Time2, _} = timer:tc(test, test2, [DBs, Data]),
    {Time3, _} = timer:tc(test, test3, [DBs, Data]),
    perfomance(Other, [{condition, N1, N2, test, Time, test2, Time2, test3, Time3} | Acc]).

gen_values(DBsN, ValueN) ->
    DBs = [list_to_atom("db" ++ integer_to_list(N)) || N <- lists:seq(1, DBsN)],
    Values = [{list_to_atom("t" ++ integer_to_list(N)), [crypto:rand_uniform(0, 9999999999999999) || _ <- DBs]}
              || N <- lists:seq(1, ValueN)],
    {DBs, Values}.

test(DBs, Values) ->
    test(DBs, Values, []).
test([], Values, Acc) ->
    lists:reverse(Acc);

test([DB | DBs], Values, Acc) ->
    {DBV, NewValues} =
        lists:foldl(fun({T, [V | Values1]}, {Acc1, Acc2}) ->
                            {[{T, V} | Acc1], [{T, Values1} | Acc2]}
                    end, {[], []}, Values),
    test(DBs, lists:reverse(NewValues), [{DB, lists:reverse(DBV)} | Acc]).

test2(DBs, Values) ->
    test2(1, DBs, [{T, erlang:list_to_tuple(Value)} || {T, Value} <- Values], []).
test2(Counter, [], Values, Acc) -> lists:reverse(Acc);
test2(Counter, [DB | DBs], Values, Acc) ->
    test2(Counter + 1, DBs, Values, [{DB, [{T, element(Counter, V)} || {T, V} <- Values]} | Acc]).

test3(DBs, Values) ->
    Result = lists:foldl(fun({T, List}, Acc) ->
                                 update_acc(List, T, Acc, [])
                         end, [[] || _ <- DBs], Values),
    NR = [lists:reverse(Value) || Value <- Result],
    lists:zip(DBs, NR).

update_acc([], _, [], NewAcc) -> lists:reverse(NewAcc);
update_acc([A| List], T, [Old | Acc], NewAcc) ->
    update_acc(List, T, Acc, [[{T, A} | Old] | NewAcc]).
