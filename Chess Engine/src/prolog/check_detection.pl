% check_detection.pl
% Detects check, checkmate, and stalemate 

:- [board_state].
:- [piece_moves].
:- [move_execution].

% ======================
% FIND KING
% ======================

find_king(Board, Color, Row, Col) :-
    member(piece(king, Color, Row, Col), Board).

% ======================
% CHECK DETECTION
% ======================

% A king is in check if any opponent piece can attack it
in_check(Board, Color) :-
    find_king(Board, Color, KingRow, KingCol),
    opposite_color(Color, OpponentColor),
    member(piece(_, OpponentColor, FromRow, FromCol), Board),
    valid_move(Board, OpponentColor, FromRow, FromCol, KingRow, KingCol).

% ======================
% LEGAL MOVE (doesnt leave king in check)
% ======================

% A move is legal if it doesnt leave your own king in check
legal_move(Board, Color, FromRow, FromCol, ToRow, ToCol) :-
    valid_move(Board, Color, FromRow, FromCol, ToRow, ToCol),
    execute_move(Board, FromRow, FromCol, ToRow, ToCol, NewBoard),
    \+ in_check(NewBoard, Color).

% Get all legal moves (FIXED VERSION)
all_legal_moves(Board, Color, Moves) :-
    findall
    (
        move(FromRow, FromCol, ToRow, ToCol),
        (
            member(piece(_, Color, FromRow, FromCol), Board),
            between(1, 8, ToRow),
            between(1, 8, ToCol),
            legal_move(Board, Color, FromRow, FromCol, ToRow, ToCol)
        ),
        Moves
    ).

% ======================
% CHECKMATE & STALEMATE
% ======================

% Checkmate: in check and no legal moves
is_checkmate(Board, Color) :-
    in_check(Board, Color),
    \+ has_legal_move(Board, Color).

% Stalemate: not in check but no legal moves
is_stalemate(Board, Color) :-
    \+ in_check(Board, Color),
    \+ has_legal_move(Board, Color).

% Check if color has any legal move (FIXED VERSION)
has_legal_move(Board, Color) :-
    member(piece(_, Color, FromRow, FromCol), Board),
    between(1, 8, ToRow),
    between(1, 8, ToCol),
    legal_move(Board, Color, FromRow, FromCol, ToRow, ToCol), !.

% Game is over if checkmate or stalemate
game_over(Board, Color, Result) :-
    ( is_checkmate(Board, Color) -> Result = checkmate
    ; is_stalemate(Board, Color) -> Result = stalemate
    ; fail
    ).