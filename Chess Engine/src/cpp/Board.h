#ifndef BOARD_H
#define BOARD_H

#include <string>
#include <vector>
#include <utility>

// Represents a chess piece
enum class PieceType 
{
    EMPTY,
    PAWN,
    ROOK,
    KNIGHT,
    BISHOP,
    QUEEN,
    KING
};

enum class Color 
{
    NONE,
    WHITE,
    BLACK
};

// Piece structure
struct Piece 
{
    PieceType type;
    Color color;
    
    Piece() : type(PieceType::EMPTY), color(Color::NONE) {}
    Piece(PieceType t, Color c) : type(t), color(c) {}
    
    bool isEmpty() const { return type == PieceType::EMPTY; }
};

// Represents a move from one square to another
struct Move 
{
    int fromRow, fromCol;
    int toRow, toCol;
    
    Move(int fr, int fc, int tr, int tc) 
        : fromRow(fr), fromCol(fc), toRow(tr), toCol(tc) {}
};

// Da Board Class
class Board 
{
private:
    Piece board[8][8];
    
    // Helper to get Unicode piece symbol
    std::string getPieceUnicode(const Piece& piece) const;
    
public:
    Board();  // Constructor
    
    // Board access
    Piece getPiece(int row, int col) const;
    void setPiece(int row, int col, const Piece& piece);
    
    // Display
    void display() const;
    
    // Convert to Prolog format
    std::string toPrologFormat() const;
    
    // Execute a move
    void executeMove(const Move& move);
    
    // Setup
    void setupInitialPosition();
    void clear();  // Empty the board
    
    // Helper functions
    static char pieceToChar(const Piece& piece);
    static std::string colorToString(Color color);
    static std::string pieceTypeToString(PieceType type);
};

#endif // BOARD_H
