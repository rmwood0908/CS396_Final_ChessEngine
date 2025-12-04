#ifndef PROLOG_INTERFACE_H
#define PROLOG_INTERFACE_H

#include "Board.h"
#include <string>
#include <vector>

class PrologInterface 
{
private:
    std::string prologPath;  // Path to Prolog files
    
    // Helper: Execute a Prolog query and get result
    std::string executePrologQuery(const std::string& query) const;
    
public:
    PrologInterface(const std::string& prologFilePath);
    
    // Check if a move is valid
    bool isValidMove(const Board& board, Color color, const Move& move) const;
    
    // Check if a move is legal
    bool isLegalMove(const Board& board, Color color, const Move& move) const;
    
    // Check if king is in check
    bool isInCheck(const Board& board, Color color) const;
    
    // Check if it's checkmate
    bool isCheckmate(const Board& board, Color color) const;
    
    // Get all legal moves for a color
    std::vector<Move> getAllLegalMoves(const Board& board, Color color) const;
    
    // Helper: Convert color enum to string
    static std::string colorToProlog(Color color);
};

#endif // PROLOG_INTERFACE_H