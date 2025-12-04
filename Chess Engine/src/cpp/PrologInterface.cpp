#include "PrologInterface.h"
#include <iostream>
#include <sstream>
#include <cstdlib>
#include <array>
#include <memory>
#include <algorithm>

PrologInterface::PrologInterface(const std::string& prologFilePath) 
    : prologPath(prologFilePath) 
    {
}

// Convert Color enum to Prolog string
std::string PrologInterface::colorToProlog(Color color) 
{
    return (color == Color::WHITE) ? "white" : "black";
}

// Execute a Prolog query using subprocess
std::string PrologInterface::executePrologQuery(const std::string& query) const {
    // Build the command to execute
    std::ostringstream cmd;
    cmd << "cd " << prologPath << " && "
        << "swipl -s check_detection.pl"
        << " -g \"(" << query << " -> write('SUCCESS') ; write('FAILURE')), halt\" "
        << "2>&1";
    
    // Execute command and capture output
    std::array<char, 128> buffer;
    std::string result;
    
    std::unique_ptr<FILE, decltype(&pclose)> pipe(
        popen(cmd.str().c_str(), "r"), pclose);
    
    if (!pipe) 
    {
        std::cerr << "Error: Failed to run Prolog command\n";
        return "";
    }
    
    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) 
    {
        result += buffer.data();
    }
    
    return result;
}

// Check if move is valid
bool PrologInterface::isValidMove(const Board& board, Color color, 
                                   const Move& move) const 
                                   {
    std::ostringstream query;
    query << "Board = " << board.toPrologFormat() << ", "
          << "valid_move(Board, " << colorToProlog(color) << ", "
          << (move.fromRow + 1) << ", " << (move.fromCol + 1) << ", "
          << (move.toRow + 1) << ", " << (move.toCol + 1) << ")";
    
    std::string result = executePrologQuery(query.str());
    
    // Check if result contains success
    return result.find("SUCCESS") != std::string::npos;
}

// Check if move is legal
bool PrologInterface::isLegalMove(const Board& board, Color color, 
                                   const Move& move) const 
                                   {
    std::ostringstream query;
    query << "Board = " << board.toPrologFormat() << ", "
          << "legal_move(Board, " << colorToProlog(color) << ", "
          << (move.fromRow + 1) << ", " << (move.fromCol + 1) << ", "
          << (move.toRow + 1) << ", " << (move.toCol + 1) << ")";
    
    std::string result = executePrologQuery(query.str());
    return result.find("SUCCESS") != std::string::npos;
}

// Check if king is in check
bool PrologInterface::isInCheck(const Board& board, Color color) const 
{
    std::ostringstream query;
    query << "Board = " << board.toPrologFormat() << ", "
          << "in_check(Board, " << colorToProlog(color) << ")";
    
    std::string result = executePrologQuery(query.str());
    return result.find("SUCCESS") != std::string::npos;
}

// Check if it's checkmate
bool PrologInterface::isCheckmate(const Board& board, Color color) const 
{
    std::ostringstream query;
    query << "Board = " << board.toPrologFormat() << ", "
          << "is_checkmate(Board, " << colorToProlog(color) << ")";
    
    std::string result = executePrologQuery(query.str());
    return result.find("SUCCESS") != std::string::npos;
}

// Get all legal moves
std::vector<Move> PrologInterface::getAllLegalMoves(const Board& board, 
                                                     Color color) const 
                                                     {
    std::vector<Move> moves;
    return moves;
}