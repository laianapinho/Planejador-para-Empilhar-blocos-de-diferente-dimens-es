% Planejador para o Mundo dos Blocos com Dimensões Diferentes
% Usando representação baseada em espaço (x,y)

% Definição dos blocos
block(a). block(b). block(c). block(d).

% Tamanhos dos blocos
size(a, 1).
size(b, 1).
size(c, 2).
size(d, 3).

% Predicado que define o espaço
% space(x, y, Status): Status pode ser clear ou occupied(Block)
% x: nível vertical (0 = mesa, 1 = primeiro nível, etc.)
% y: posição horizontal (0, 1, 2, 3, 4, 5, 6)

% Verifica se um bloco está livre (nada sobre ele)
is_clear(Block, State) :-
    block(Block),
    findall(Y, member(space(_, Y, occupied(Block)), State), Positions),
    level_above(Block, State, Level),
    \+ (member(space(Level, Y, occupied(_)), State), member(Y, Positions)).

% Encontra o nível vertical de um bloco
block_level(Block, State, Level) :-
    member(space(Level, _, occupied(Block)), State),
    !.

% Calcula o nível acima de um bloco
level_above(Block, State, LevelAbove) :-
    block_level(Block, State, Level),
    LevelAbove is Level + 1.

% Verifica se um espaço está livre para receber um bloco
space_is_clear(X, Y, State) :-
    member(space(X, Y, clear), State).

% Verifica se uma posição (y) na mesa está livre para receber um bloco
position_is_clear(Pos, Size, State) :-
    EndPos is Pos + Size - 1,
    all_positions_clear(0, Pos, EndPos, State).

% Verifica se todas as posições em um intervalo estão livres
all_positions_clear(_, Pos, EndPos, _) :- Pos > EndPos, !.
all_positions_clear(X, Pos, EndPos, State) :-
    space_is_clear(X, Pos, State),
    NextPos is Pos + 1,
    all_positions_clear(X, NextPos, EndPos, State).

% Verifica se um bloco pode ser colocado sobre outro
can_place_on_block(Block, Support, State) :-
    block(Support),
    size(Block, BlockSize),
    size(Support, SupportSize),
    BlockSize =< SupportSize,
    block_level(Support, State, SupportLevel),
    Level is SupportLevel + 1,
    findall(Y, member(space(SupportLevel, Y, occupied(Support)), State), SupportPositions),
    min_list(SupportPositions, MinY),
    max_list(SupportPositions, MaxY),
    % Verifica se há espaço suficiente e livre no bloco de suporte
    EndBlockPos is MinY + BlockSize - 1,
    EndBlockPos =< MaxY,
    all_positions_clear(Level, MinY, EndBlockPos, State).

% Encontra os valores mínimo e máximo de uma lista
min_list([X], X) :- !.
min_list([H|T], Min) :-
    min_list(T, Min1),
    Min is min(H, Min1).

max_list([X], X) :- !.
max_list([H|T], Max) :-
    max_list(T, Max1),
    Max is max(H, Max1).

% Definição da ação move
can(move(Block, From, To), [
    block_is_clear(Block),
    destination_is_clear(To, Block),
    on(Block, From)
]) :-
    block(Block),
    (block(From) ; From = table),
    (block(To) ; To = table),
    From \== To,
    Block \== From,
    Block \== To.

% Condições para mover um bloco
block_is_clear(Block) :-
    is_clear(Block, _).

destination_is_clear(table, Block) :-
    size(Block, _).
destination_is_clear(Support, Block) :-
    block(Support),
    can_place_on_block(Block, Support, _).

% Efeitos da ação move - CORRIGIDO para usar adds/2
adds(move(Block, _, table), AddList) :-
    size(Block, Size),
    findall(space(0, Y, occupied(Block)), between(0, Size-1, Y), NewSpaces),
    findall(on(Block, Y), between(0, Size-1, Y), OnRelations),
    append(NewSpaces, OnRelations, AddList).

adds(move(Block, _, Support), AddList) :-
    block(Support),
    size(Block, BlockSize),
    block_level(Support, _, SupportLevel),
    Level is SupportLevel + 1,
    findall(Y, member(space(SupportLevel, Y, occupied(Support)), _), SupportPositions),
    min_list(SupportPositions, MinY),
    findall(space(Level, Y, occupied(Block)), 
            (between(0, BlockSize-1, Offset), Y is MinY + Offset), 
            NewSpaces),
    findall(on(Block, Support), [Support], OnRelations),
    append(NewSpaces, OnRelations, AddList).

deletes(move(Block, _, _), DeleteList) :-
    findall(space(X, Y, occupied(Block)), member(space(X, Y, occupied(Block)), _), OldSpaces),
    findall(space(X, Y, clear), member(space(X, Y, occupied(Block)), _), NewClearSpaces),
    findall(on(Block, Support), member(on(Block, Support), _), OldOnRelations),
    append(OldSpaces, OldOnRelations, DeleteList1),
    append(DeleteList1, NewClearSpaces, DeleteList).

% Planejador de meios-fins
plan(State, Goals, [], State) :-
    satisfied(State, Goals).

plan(State, Goals, Plan, FinalState) :-
    conc(Plan, _, _),
    conc(PrePlan, [Action | PostPlan], Plan),
    select(State, Goals, Goal),
    achieves(Action, Goal, State),
    can(Action, Condition),
    check_conditions(Action, Condition, State),
    regress(Goals, Action, RegressedGoals, State),
    plan(State, RegressedGoals, PrePlan, MidState1),
    apply(MidState1, Action, MidState2),
    plan(MidState2, Goals, PostPlan, FinalState).

% Verifica se Goals são verdadeiros em State
satisfied(State, []).
satisfied(State, [Goal | Goals]) :-
    member(Goal, State),
    satisfied(State, Goals).

% Seleciona um objetivo não satisfeito
select(State, Goals, Goal) :-
    member(Goal, Goals),
    \+ member(Goal, State).

% Verifica se uma ação alcança um objetivo - CORRIGIDO para usar adds/2 
achieves(Action, Goal, State) :-
    adds(Action, AddList),
    member(Goal, AddList).

% Verificação dinâmica das condições
check_conditions(_, [], _).
check_conditions(Action, [Cond|Rest], State) :-
    check_condition(Action, Cond, State),
    check_conditions(Action, Rest, State).

check_condition(move(Block, _, _), block_is_clear(Block), State) :-
    is_clear(Block, State).
check_condition(move(Block, _, table), destination_is_clear(table, Block), State) :-
    size(Block, Size),
    position_is_clear(0, Size, State).
check_condition(move(Block, _, Support), destination_is_clear(Support, Block), State) :-
    block(Support),
    can_place_on_block(Block, Support, State).
check_condition(move(Block, From, _), on(Block, From), State) :-
    member(on(Block, From), State).

% Regressão de objetivos - CORRIGIDO para usar adds/2 e deletes/2
regress(Goals, Action, RegressedGoals, State) :-
    adds(Action, AddList),
    deletes(Action, DelList),
    delete_all(Goals, AddList, Goals1),
    can(Action, Condition),
    append(Condition, Goals1, RegressedGoals).

% Aplica uma ação a um estado - CORRIGIDO para usar adds/2 e deletes/2
apply(State, Action, NewState) :-
    deletes(Action, DelList),
    delete_all(State, DelList, State1),
    adds(Action, AddList),
    append(AddList, State1, NewState).

% Funções auxiliares
delete_all([], _, []).
delete_all([X | L1], L2, Diff) :-
    member(X, L2), !,
    delete_all(L1, L2, Diff).
delete_all([X | L1], L2, [X | Diff]) :-
    delete_all(L1, L2, Diff).

conc([], L, L).
conc([X | L1], L2, [X | L3]) :-
    conc(L1, L2, L3).

append([], L, L).
append([H|T], L, [H|R]) :- 
    append(T, L, R).

between(X, Y, X) :- X =< Y.
between(X, Y, Z) :- X < Y, X1 is X + 1, between(X1, Y, Z).

% Estado inicial da Situação 1
initial_state1([
    % Posições na mesa (nível 0)
    space(0, 0, clear),
    space(0, 1, occupied(c)),  % c ocupa posições 1-2
    space(0, 2, occupied(c)),
    space(0, 3, occupied(a)),  % a ocupa posição 3
    space(0, 4, occupied(b)),  % b ocupa posição 4
    space(0, 5, clear),
    space(0, 6, clear),
    
    % Primeiro nível (nível 1)
    space(1, 0, clear),
    space(1, 1, clear),
    space(1, 2, clear),
    space(1, 3, occupied(d)),  % d ocupa posições 3-5
    space(1, 4, occupied(d)),
    space(1, 5, occupied(d)),
    space(1, 6, clear),
    
    % Segundo nível (nível 2)
    space(2, 0, clear),
    space(2, 1, clear),
    space(2, 2, clear),
    space(2, 3, clear),
    space(2, 4, clear),
    space(2, 5, clear),
    space(2, 6, clear),
    
    % Relações de apoio
    on(c, table),
    on(a, table),
    on(b, table),
    on(d, a),
    on(d, b),
    
    % Tamanhos dos blocos
    size(a, 1),
    size(b, 1),
    size(c, 2),
    size(d, 3)
]).

% Estado objetivo da Situação 1
goal_state1([
    % Posições na mesa (nível 0)

    space(0, 4, occupied(d)),  % d ocupa posições 4-6
    space(0, 5, occupied(d)),
    space(0, 6, occupied(d)),
    
    % Primeiro nível (nível 1)

    space(1, 4, occupied(c)),  % c ocupa posições 4-5
    space(1, 5, occupied(c)),
    
    % Segundo nível (nível 2)

    space(2, 4, occupied(a)),  % a ocupa posição 4
    space(2, 5, occupied(b)),  % b ocupa posição 5
    
    % Relações de apoio
    on(d, table),
    on(c, d),
    on(a, c),
    on(b, c)
    
]).

% Estado inicial da Situação 2
initial_state2([
    % Posições na mesa (nível 0)
    space(0, 0, occupied(c)),
    space(0, 1, occupied(c)),  % c ocupa posições 1-2
    space(0, 2, clear),
    space(0, 3, occupied(d)),  % a ocupa posição 3
    space(0, 4, occupied(d)),  % b ocupa posição 4
    space(0, 5, occupied(d)),
   
    
    % Primeiro nível (nível 1)
    space(1, 0, occupied(a)),
    space(1, 1, occupied(b)),
    space(1, 2, clear),
    space(1, 3, clear),  % d ocupa posições 3-5
    space(1, 4, clear),
    space(1, 5, clear),
    
    % Segundo nível (nível 2)
    space(2, 0, clear),
    space(2, 1, clear),
    space(2, 2, clear),
    space(2, 3, clear),
    space(2, 4, clear),
    space(2, 5, clear),
 
    
    % Relações de apoio
    on(c, table),
    on(a, c),
    on(b, c),
    on(d, table)
    
]).

goal_state2([
   
    % Primeiro nível (nível )

    % Relações de apoio
    on(a, c),
    on(b, c),
    on(c, d),
    on(d, table),

    space(0, 3, occupied(d)),
    space(0, 4, occupied(d)),
    space(0, 5, occupied(d)),
    space(1, 4, occupied(c)),
    space(1, 5, occupied(c)),
    space(2, 4, occupied(a)),  % c ocupa posições 4-5
    space(2, 5, occupied(b))
]).


goal_state3([
   
    % Primeiro nível (nível )

    % Relações de apoio
    on(a, d),
    on(b, c),
    on(c, table),
    on(d, table),

    space(0, 2, occupied(d)),
    space(0, 3, occupied(d)),
    space(0, 4, occupied(d)),
    space(1, 2, occupied(c)),
    space(1, 3, occupied(c)),
    space(1, 4, occupied(a)),  % c ocupa posições 4-5
    space(2, 3, occupied(b))
 
]).


goal_state4([
   
    % Primeiro nível (nível )

    % Relações de apoio
    on(a, table),
    on(b, table),
    on(c, table),
    on(d, c),
    on(d, b),
    on(d, a),
    space(1, 3, occupied(d)),
    space(1, 4, occupied(d)),
    space(1, 5, occupied(d)),
    space(0, 2, occupied(c)),
    space(0, 3, occupied(c)),
    space(0, 4, occupied(a)),  % c ocupa posições 4-5
    space(0, 5, occupied(b))
 
]).

% Função de teste
test1 :-
    initial_state1(Initial),
    goal_state1(Goal),
    nl, write('Estado inicial: '), nl,
    print_state(Initial), nl,
    write('Estado objetivo: '), nl,
    print_state(Goal), nl,
    (plan(Initial, Goal, Plan, FinalState) ->
        format('Plano encontrado:~n~w~n~n', [Plan]),
        write('Estado final: '), nl,
        print_state(FinalState)
    ;
        write('Não foi possível encontrar um plano')
    ).

test2 :-
    initial_state2(Initial),
    goal_state2(Goal),
    nl, write('Estado inicial: '), nl,
    print_state(Initial), nl,
    write('Estado objetivo: '), nl,
    print_state(Goal), nl,
    (plan(Initial, Goal, Plan, FinalState) ->
        format('Plano encontrado:~n~w~n~n', [Plan]),
        write('Estado final: '), nl,
        print_state(FinalState)
    ;
        write('Não foi possível encontrar um plano')
    ).


test3 :-
    initial_state1(Initial),
    goal_state3(Goal),
    nl, write('Estado inicial: '), nl,
    print_state(Initial), nl,
    write('Estado objetivo: '), nl,
    print_state(Goal), nl,
    (plan(Initial, Goal, Plan, FinalState) ->
        format('Plano encontrado:~n~w~n~n', [Plan]),
        write('Estado final: '), nl,
        print_state(FinalState)
    ;
        write('Não foi possível encontrar um plano')
    ).

test4 :-
    initial_state1(Initial),
    goal_state4(Goal),
    nl, write('Estado inicial: '), nl,
    print_state(Initial), nl,
    write('Estado objetivo: '), nl,
    print_state(Goal), nl,
    (plan(Initial, Goal, Plan, FinalState) ->
        format('Plano encontrado:~n~w~n~n', [Plan]),
        write('Estado final: '), nl,
        print_state(FinalState)
    ;
        write('Não foi possível encontrar um plano')
    ).


% Função para imprimir o estado de forma mais legível
print_state([]).
print_state([Rel|Rest]) :-
    write('  '), write(Rel), nl,
    print_state(Rest).