% piece_moves.pl
% Defines possible legal moves for each piece type

:- [board_state].

% ======================
% PAWN MOVES
% ======================

valid_pawn_move(Board, Color, FromRow, FromCol, ToRow, ToCol) :-
    (Color = white -> Direction = 1 ; Direction = -1),
    ToRow is FromRow + Direction,
    ToCol = FromCol,
    is_empty(Board, ToRow, ToCol).

valid_pawn_move(Board, Color, FromRow, FromCol, ToRow, ToCol) :-
    (Color = white -> FromRow = 2, Direction = 1 ; FromRow = 7, Direction = -1),
    ToRow is FromRow + 2 * Direction,
    ToCol = FromCol,
    MiddleRow is FromRow + Direction,
    is_empty(Board, MiddleRow, ToCol),
    is_empty(Board, ToRow, ToCol).

valid_pawn_move(Board, Color, FromRow, FromCol, ToRow, ToCol) :-
    (Color = white -> Direction = 1 ; Direction = -1),
    ToRow is FromRow + Direction,
    (ToCol is FromCol + 1 ; ToCol is FromCol - 1),
    is_opponent(Board, ToRow, ToCol, Color).

% ======================
% ROOK MOVES
% ======================

valid_rook_move(Board, FromRow, FromCol, ToRow, ToCol) :-
    (FromRow = ToRow ; FromCol = ToCol),
    \+ (FromRow = ToRow, FromCol = ToCol),  % Not same square
    path_clear(Board, FromRow, FromCol, ToRow, ToCol).

% ======================
% KNIGHT MOVES
% ======================

valid_knight_move(FromRow, FromCol, ToRow, ToCol) :-
    RowDiff is abs(ToRow - FromRow),
    ColDiff is abs(ToCol - FromCol),
    ( (RowDiff = 2, ColDiff = 1) ; (RowDiff = 1, ColDiff = 2) ).

% ======================
% BISHOP MOVES
% ======================

valid_bishop_move(Board, FromRow, FromCol, ToRow, ToCol) :-
    RowDiff is abs(ToRow - FromRow),
    ColDiff is abs(ToCol - FromCol),
    RowDiff = ColDiff,
    RowDiff > 0,
    path_clear(Board, FromRow, FromCol, ToRow, ToCol).

% ======================
% QUEEN MOVES
% ======================

valid_queen_move(Board, FromRow, FromCol, ToRow, ToCol) :-
    ( valid_rook_move(Board, FromRow, FromCol, ToRow, ToCol) ;
      valid_bishop_move(Board, FromRow, FromCol, ToRow, ToCol) ).

% ======================
% KING MOVES
% ======================

valid_king_move(FromRow, FromCol, ToRow, ToCol) :-
    RowDiff is abs(ToRow - FromRow),
    ColDiff is abs(ToCol - FromCol),
    RowDiff =< 1,
    ColDiff =< 1,
    \+ (RowDiff = 0, ColDiff = 0).

% ======================
% PATH CHECKING
% ======================

path_clear(Board, FromRow, FromCol, ToRow, ToCol) :-
    RowDir is sign(ToRow - FromRow),
    ColDir is sign(ToCol - FromCol),
    NextRow is FromRow + RowDir,
    NextCol is FromCol + ColDir,
    check_path(Board, NextRow, NextCol, ToRow, ToCol, RowDir, ColDir).

% Base case: reached destination
check_path(_, ToRow, ToCol, ToRow, ToCol, _, _).

% Recursive case: keep checking path
check_path(Board, CurrentRow, CurrentCol, ToRow, ToCol, RowDir, ColDir) :-
    CurrentRow \= ToRow,  % Havent reached destination
    is_empty(Board, CurrentRow, CurrentCol),  % Current square must be empty
    NextRow is CurrentRow + RowDir,
    NextCol is CurrentCol + ColDir,
    check_path(Board, NextRow, NextCol, ToRow, ToCol, RowDir, ColDir).

check_path(Board, CurrentRow, CurrentCol, ToRow, ToCol, RowDir, ColDir) :-
    CurrentCol \= ToCol,  % Havent reached destination  
    is_empty(Board, CurrentRow, CurrentCol),  % Current square must be empty
    NextRow is CurrentRow + RowDir,
    NextCol is CurrentCol + ColDir,
    check_path(Board, NextRow, NextCol, ToRow, ToCol, RowDir, ColDir).

% ======================
% MAIN MOVE VALIDATION
% ======================

valid_move(Board, Color, FromRow, FromCol, ToRow, ToCol) :-
    on_board(ToRow, ToCol),
    piece_at(Board, FromRow, FromCol, piece(Type, Color, FromRow, FromCol)),
    ( is_empty(Board, ToRow, ToCol) ; is_opponent(Board, ToRow, ToCol, Color) ),
    ( Type = pawn   -> valid_pawn_move(Board, Color, FromRow, FromCol, ToRow, ToCol)
    ; Type = rook   -> valid_rook_move(Board, FromRow, FromCol, ToRow, ToCol)
    ; Type = knight -> valid_knight_move(FromRow, FromCol, ToRow, ToCol)
    ; Type = bishop -> valid_bishop_move(Board, FromRow, FromCol, ToRow, ToCol)
    ; Type = queen  -> valid_queen_move(Board, FromRow, FromCol, ToRow, ToCol)
    ; Type = king   -> valid_king_move(FromRow, FromCol, ToRow, ToCol)
    ).