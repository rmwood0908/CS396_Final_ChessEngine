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
    std::ostringstream cmd;
    cmd << "cd " << prologPath << " && "
        << "swipl -s check_detection.pl"
        << " -g \"(" << query 
        << " -> write('SUCCESS') ; write('FAILURE')), halt\" "
        << "2>&1";

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

// Runs the given goal in an external process and returns its text output
std::string PrologInterface::executePrologRaw(const std::string& goal) const
{
    // Build the shell command that changes directory and runs the script
    std::ostringstream cmd;
    cmd << "cd " << prologPath << " && "
        << "swipl -s check_detection.pl "
        << "-g \"" << goal << ", halt\" "
        << "2>&1";

    // Buffer used to read chunks from the process output
    std::array<char, 256> buffer;
    // Collects the full output as a single string
    std::string result;

    // Start the process and attach a pipe to its standard output
    std::unique_ptr<FILE, decltype(&pclose)> pipe(
        popen(cmd.str().c_str(), "r"), pclose);
    // If the process failed to start, return an empty result
    if (!pipe)
    {
        std::cerr << "Error: Failed to run external command (raw)\n";
        return "";
    }

    // Read all available output from the process
    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr)
    {
        result += buffer.data();
    }

    // Return whatever the process printed
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

// Builds a list of legal moves
std::vector<Move> PrologInterface::getAllLegalMoves(const Board& board, 
                                                    Color color) const 
{
    std::vector<Move> moves;

    // Construct the goal string that encodes the current board and color
    std::ostringstream goal;
    goal << "Board = " << board.toPrologFormat() << ", "
         << "all_legal_moves(Board, " << colorToProlog(color) << ", Moves), "
         << "write(Moves)";

    // Run the goal and capture the raw output text
    std::string result = executePrologRaw(goal.str());

    // Scan through the output for every occurrence of move(FR,FC,TR,TC)
    std::size_t pos = 0;
    while (true)
    {
        // Find the next "move(" substring
        std::size_t start = result.find("move(", pos);
        if (start == std::string::npos)
            break;

        // Skip past the "move(" prefix
        start += 5;

        // Hold coordinates and punctuation parsed from the text
        int fr = 0, fc = 0, tr = 0, tc = 0;
        char c1 = 0, c2 = 0, c3 = 0, closing = 0;

        // Parse "FR,FC,TR,TC)" starting at this position
        std::stringstream ss(result.substr(start));
        ss >> fr >> c1 >> fc >> c2 >> tr >> c3 >> tc >> closing;

        // If parsing succeeded and the format is correct, store the move
        if (ss && c1 == ',' && c2 == ',' && c3 == ',' && closing == ')')
        {
            // Convert from 1-based indices to 0-based indices
            moves.emplace_back(fr - 1, fc - 1, tr - 1, tc - 1);
        }

        // Advance the search position to after this closing parenthesis
        pos = result.find(")", start);
        if (pos == std::string::npos)
            break;
        ++pos;
    }

    // Return the list of parsed moves
    return moves;
}








