% board_state.pl
% Basic board representation

% Represents a piece: piece(Type, Color, Row, Col)
% Type: pawn, rook, knight, bishop, queen, king
% Color: white, black
% Row/Col: 1-8

% Initial board setup
initial_board
([
    % White pieces
    piece(rook, white, 1, 1), piece(knight, white, 1, 2),
    piece(bishop, white, 1, 3), piece(queen, white, 1, 4),
    piece(king, white, 1, 5), piece(bishop, white, 1, 6),
    piece(knight, white, 1, 7), piece(rook, white, 1, 8),
    piece(pawn, white, 2, 1), piece(pawn, white, 2, 2),
    piece(pawn, white, 2, 3), piece(pawn, white, 2, 4),
    piece(pawn, white, 2, 5), piece(pawn, white, 2, 6),
    piece(pawn, white, 2, 7), piece(pawn, white, 2, 8),
    
    % Black pieces
    piece(rook, black, 8, 1), piece(knight, black, 8, 2),
    piece(bishop, black, 8, 3), piece(queen, black, 8, 4),
    piece(king, black, 8, 5), piece(bishop, black, 8, 6),
    piece(knight, black, 8, 7), piece(rook, black, 8, 8),
    piece(pawn, black, 7, 1), piece(pawn, black, 7, 2),
    piece(pawn, black, 7, 3), piece(pawn, black, 7, 4),
    piece(pawn, black, 7, 5), piece(pawn, black, 7, 6),
    piece(pawn, black, 7, 7), piece(pawn, black, 7, 8)
]).

% Check if a square is on the board
on_board(Row, Col) :-
    Row >= 1, Row =< 8,
    Col >= 1, Col =< 8.

% Find a piece at a specific position
piece_at(Board, Row, Col, Piece) :-
    member(piece(Type, Color, Row, Col), Board),
    Piece = piece(Type, Color, Row, Col).

% Check if a square is empty
is_empty(Board, Row, Col) :-
    on_board(Row, Col),
    \+ member(piece(_, _, Row, Col), Board).

% Check if a square contains an opponents piece
is_opponent(Board, Row, Col, Color) :-
    piece_at(Board, Row, Col, piece(_, OpponentColor, Row, Col)),
    opposite_color(Color, OpponentColor).

% Define opposite colors
opposite_color(white, black).
opposite_color(black, white).