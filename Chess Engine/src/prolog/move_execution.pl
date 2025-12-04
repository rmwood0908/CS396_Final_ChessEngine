% move_execution.pl
% Handles execution of moves and board updates

:- [board_state].
:- [piece_moves].

% Execute a move: remove piece from old position, place at new position
execute_move(OldBoard, FromRow, FromCol, ToRow, ToCol, NewBoard) :-
    % Get the piece being moved
    piece_at(OldBoard, FromRow, FromCol, piece(Type, Color, FromRow, FromCol)),
    
    % Remove piece from old position
    select(piece(Type, Color, FromRow, FromCol), OldBoard, TempBoard),
    
    % Remove any piece at destination (capture)
    ( piece_at(TempBoard, ToRow, ToCol, CapturedPiece) ->
        select(CapturedPiece, TempBoard, TempBoard2)
    ;   TempBoard2 = TempBoard
    ),
    
    % Add piece to new position
    NewBoard = [piece(Type, Color, ToRow, ToCol) | TempBoard2].

% Get all valid moves for a given color
all_valid_moves(Board, Color, Moves) :-
    findall(
        move(FromRow, FromCol, ToRow, ToCol),
        (
            member(piece(_, Color, FromRow, FromCol), Board),
            between(1, 8, ToRow),
            between(1, 8, ToCol),
            valid_move(Board, Color, FromRow, FromCol, ToRow, ToCol)
        ),
        Moves
    ).

% Display the board (for debugging)
display_board(Board) :-
    nl,
    display_row(Board, 8),
    display_row(Board, 7),
    display_row(Board, 6),
    display_row(Board, 5),
    display_row(Board, 4),
    display_row(Board, 3),
    display_row(Board, 2),
    display_row(Board, 1),
    nl.

display_row(Board, Row) :-
    write(Row), write(' '),
    display_square(Board, Row, 1),
    display_square(Board, Row, 2),
    display_square(Board, Row, 3),
    display_square(Board, Row, 4),
    display_square(Board, Row, 5),
    display_square(Board, Row, 6),
    display_square(Board, Row, 7),
    display_square(Board, Row, 8),
    nl.

display_square(Board, Row, Col) :-
    ( piece_at(Board, Row, Col, piece(Type, Color, _, _)) ->
        piece_symbol(Type, Color, Symbol),
        write(Symbol)
    ;   write('.')
    ),
    write(' ').

% Piece symbols for display
piece_symbol(pawn, white, 'P').
piece_symbol(rook, white, 'R').
piece_symbol(knight, white, 'N').
piece_symbol(bishop, white, 'B').
piece_symbol(queen, white, 'Q').
piece_symbol(king, white, 'K').
piece_symbol(pawn, black, 'p').
piece_symbol(rook, black, 'r').
piece_symbol(knight, black, 'n').
piece_symbol(bishop, black, 'b').
piece_symbol(queen, black, 'q').
piece_symbol(king, black, 'k').