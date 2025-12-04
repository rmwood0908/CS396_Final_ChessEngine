#include "Board.h"
#include <iostream>
#include <sstream>

// Constructor - sets up initial chess position
Board::Board() 
{
    setupInitialPosition();
}

// Get piece at position
Piece Board::getPiece(int row, int col) const 
{
    if (row < 0 || row >= 8 || col < 0 || col >= 8) 
    {
        return Piece();  // Return empty piece if out of bounds
    }
    return board[row][col];
}

// Set piece at position
void Board::setPiece(int row, int col, const Piece& piece) 
{
    if (row >= 0 && row < 8 && col >= 0 && col < 8) 
    {
        board[row][col] = piece;
    }
}

// Clear the board
void Board::clear() 
{
    for (int row = 0; row < 8; row++) 
    {
        for (int col = 0; col < 8; col++) 
        {
            board[row][col] = Piece();
        }
    }
}

// Setup initial chess position
void Board::setupInitialPosition() 
{
    clear();
    
    // White pieces
    board[0][0] = Piece(PieceType::ROOK, Color::WHITE);
    board[0][1] = Piece(PieceType::KNIGHT, Color::WHITE);
    board[0][2] = Piece(PieceType::BISHOP, Color::WHITE);
    board[0][3] = Piece(PieceType::QUEEN, Color::WHITE);
    board[0][4] = Piece(PieceType::KING, Color::WHITE);
    board[0][5] = Piece(PieceType::BISHOP, Color::WHITE);
    board[0][6] = Piece(PieceType::KNIGHT, Color::WHITE);
    board[0][7] = Piece(PieceType::ROOK, Color::WHITE);
    
    // White pawns
    for (int col = 0; col < 8; col++) 
    {
        board[1][col] = Piece(PieceType::PAWN, Color::WHITE);
    }
    
    // Black pawns
    for (int col = 0; col < 8; col++) 
    {
        board[6][col] = Piece(PieceType::PAWN, Color::BLACK);
    }
    
    // Black pieces
    board[7][0] = Piece(PieceType::ROOK, Color::BLACK);
    board[7][1] = Piece(PieceType::KNIGHT, Color::BLACK);
    board[7][2] = Piece(PieceType::BISHOP, Color::BLACK);
    board[7][3] = Piece(PieceType::QUEEN, Color::BLACK);
    board[7][4] = Piece(PieceType::KING, Color::BLACK);
    board[7][5] = Piece(PieceType::BISHOP, Color::BLACK);
    board[7][6] = Piece(PieceType::KNIGHT, Color::BLACK);
    board[7][7] = Piece(PieceType::ROOK, Color::BLACK);
}

// Convert piece to Unicode character for display
char Board::pieceToChar(const Piece& piece) 
{
    if (piece.isEmpty()) 
    {
        return '.';
    }
    
    char c;
    switch (piece.type) 
    {
        case PieceType::PAWN:   c = 'P'; break;
        case PieceType::ROOK:   c = 'R'; break;
        case PieceType::KNIGHT: c = 'N'; break;
        case PieceType::BISHOP: c = 'B'; break;
        case PieceType::QUEEN:  c = 'Q'; break;
        case PieceType::KING:   c = 'K'; break;
        default: c = '?';
    }
    
    // Lowercase for black pieces
    if (piece.color == Color::BLACK) 
    {
        c = tolower(c);
    }
    
    return c;
}

// Display board with Unicode pieces and colored squares
void Board::display() const 
{
    std::cout << "\n";
    std::cout << "    a   b   c   d   e   f   g   h  \n";
    std::cout << "  ╔═══╦═══╦═══╦═══╦═══╦═══╦═══╦═══╗\n";
    
    // Display from rank 8 down to rank 1 (rows 7 to 0)
    for (int row = 7; row >= 0; row--) 
    {
        std::cout << (row + 1) << " ║";
        
        for (int col = 0; col < 8; col++) 
        {
            Piece piece = board[row][col];
            
            // Alternate square colors with shading
            bool isLightSquare = (row + col) % 2 == 0;
            
            if (!piece.isEmpty()) 
            {
                // Print the piece with Unicode
                std::string pieceSymbol = getPieceUnicode(piece);
                std::cout << " " << pieceSymbol << " ";
            } 
            else 
            {
                // Empty square - show shading
                if (isLightSquare) 
                {
                    std::cout << "   ";  // Light square
                } 
                else 
                {
                    std::cout << " · ";  // Dark square with dot
                }
            }
            
            std::cout << "║";
        }
        
        std::cout << " " << (row + 1) << "\n";
        
        // Print row separator (except after last row)
        if (row > 0) 
        {
            std::cout << "  ╠═══╬═══╬═══╬═══╬═══╬═══╬═══╬═══╣\n";
        }
    }
    
    std::cout << "  ╚═══╩═══╩═══╩═══╩═══╩═══╩═══╩═══╝\n";
    std::cout << "    a   b   c   d   e   f   g   h  \n\n";
}

// Get Unicode symbol for piece
std::string Board::getPieceUnicode(const Piece& piece) const
{
    if (piece.color == Color::WHITE) 
    {
        switch (piece.type) 
        {
            case PieceType::KING:   return "♔";
            case PieceType::QUEEN:  return "♕";
            case PieceType::ROOK:   return "♖";
            case PieceType::BISHOP: return "♗";
            case PieceType::KNIGHT: return "♘";
            case PieceType::PAWN:   return "♙";
            default: return " ";
        }
    } 
    else 
    {
        switch (piece.type) 
        {
            case PieceType::KING:   return "♚";
            case PieceType::QUEEN:  return "♛";
            case PieceType::ROOK:   return "♜";
            case PieceType::BISHOP: return "♝";
            case PieceType::KNIGHT: return "♞";
            case PieceType::PAWN:   return "♟";
            default: return " ";
        }
    }
}

// Convert color to string
std::string Board::colorToString(Color color) 
{
    switch (color) 
    {
        case Color::WHITE: return "white";
        case Color::BLACK: return "black";
        default: return "none";
    }
}

// Convert piece type to string
std::string Board::pieceTypeToString(PieceType type) 
{
    switch (type) 
    {
        case PieceType::PAWN:   return "pawn";
        case PieceType::ROOK:   return "rook";
        case PieceType::KNIGHT: return "knight";
        case PieceType::BISHOP: return "bishop";
        case PieceType::QUEEN:  return "queen";
        case PieceType::KING:   return "king";
        default: return "empty";
    }
}

// Convert board to Prolog format
// Returns: "[piece(rook,white,1,1), piece(knight,white,1,2), ...]"
std::string Board::toPrologFormat() const 
{
    std::ostringstream oss;
    oss << "[";
    
    bool first = true;
    
    // Iterate through board and build Prolog list
    for (int row = 0; row < 8; row++) 
    {
        for (int col = 0; col < 8; col++) 
        {
            Piece piece = board[row][col];
            
            if (!piece.isEmpty()) 
            {
                if (!first) 
                {
                    oss << ", ";
                }
                
                // Prolog uses 1-indexed positions (1-8, not 0-7)
                oss << "piece(" 
                    << pieceTypeToString(piece.type) << ", "
                    << colorToString(piece.color) << ", "
                    << (row + 1) << ", "
                    << (col + 1) << ")";
                
                first = false;
            }
        }
    }
    
    oss << "]";
    return oss.str();
}

// Execute a move on the board
void Board::executeMove(const Move& move) 
{
    // Get the piece at the starting position
    Piece piece = getPiece(move.fromRow, move.fromCol);
    
    // Move it to the destination
    setPiece(move.toRow, move.toCol, piece);
    
    // Clear the starting position
    setPiece(move.fromRow, move.fromCol, Piece());
}
