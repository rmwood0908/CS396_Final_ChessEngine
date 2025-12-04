#include "Game.h"
#include <iostream>
#include <sstream>
#include <cctype>
#include <algorithm>

Game::Game(const std::string& prologPath) 
    : prolog(prologPath), currentPlayer(Color::WHITE), gameOver(false) 
    {
    board.setupInitialPosition();
}

// Switch between white and black
void Game::switchPlayer() 
{
    currentPlayer = (currentPlayer == Color::WHITE) ? Color::BLACK : Color::WHITE;
}

// Display current game status
void Game::displayStatus() const 
{
    std::cout << "\n";
    std::cout << "╔════════════════════════════════════════╗\n";
    
    if (currentPlayer == Color::WHITE) 
    {
        std::cout << "║       Current Player: WHITE ♔          ║\n";
    } 
    else 
    {
        std::cout << "║       Current Player: BLACK ♚          ║\n";
    }
    
    std::cout << "╚════════════════════════════════════════╝\n";
}

// Parse move input
Move Game::parseMove(const std::string& input) const 
{
    std::string clean = input;
    // Remove spaces
    clean.erase(std::remove(clean.begin(), clean.end(), ' '), clean.end());
    
    if (clean.length() != 4) 
    {
        return Move(-1, -1, -1, -1);  // Invalid
    }
    
    // Parse: e2e4 -> from=(1,4), to=(3,4)
    char fromFile = tolower(clean[0]);
    char fromRank = clean[1];
    char toFile = tolower(clean[2]);
    char toRank = clean[3];
    
    // Convert chess notation to array indices
    // Files: a-h -> 0-7
    // Ranks: 1-8 -> 0-7
    int fromCol = fromFile - 'a';
    int fromRow = fromRank - '1';
    int toCol = toFile - 'a';
    int toRow = toRank - '1';
    
    // Validate ranges
    if (fromCol < 0 || fromCol > 7 || fromRow < 0 || fromRow > 7 ||
        toCol < 0 || toCol > 7 || toRow < 0 || toRow > 7) 
        {
        return Move(-1, -1, -1, -1);  // Invalid
    }
    
    return Move(fromRow, fromCol, toRow, toCol);
}

// Check if input format is valid
bool Game::isValidInput(const std::string& input) const 
{
    std::string clean = input;
    clean.erase(std::remove(clean.begin(), clean.end(), ' '), clean.end());
    
    if (clean.length() != 4) return false;
    
    // Check format: letter, digit, letter, digit
    return isalpha(clean[0]) && isdigit(clean[1]) &&
           isalpha(clean[2]) && isdigit(clean[3]);
}

// Get move from human player
Move Game::getHumanMove() 
{
    std::string input;
    
    while (true) 
    {
        std::cout << "\nEnter your move (e.g., 'e2 e4' or 'e2e4'): ";
        std::getline(std::cin, input);
        
        // Check for quit
        if (input == "quit" || input == "exit") 
        {
            gameOver = true;
            return Move(-1, -1, -1, -1);
        }
        
        if (!isValidInput(input)) 
        {
            std::cout << "Invalid format! Use format like 'e2 e4'\n";
            continue;
        }
        
        Move move = parseMove(input);
        
        // Check if piece at starting position belongs to current player
        Piece piece = board.getPiece(move.fromRow, move.fromCol);
        if (piece.isEmpty()) 
        {
            std::cout << "No piece at that position!\n";
            continue;
        }
        if (piece.color != currentPlayer) 
        {
            std::cout << "That's not your piece!\n";
            continue;
        }
        
        return move;
    }
}

// Get AI move (placeholder - returns random legal move or invalid move)
Move Game::getAIMove() 
{
    std::cout << "\nAI is thinking...\n";
    // TODO: Call Scheme AI here
    // For now, just return an invalid move
    return Move(-1, -1, -1, -1);
}

// Attempt to make a move
bool Game::makeMove(const Move& move) 
{
    // Validate with Prolog
    if (!prolog.isLegalMove(board, currentPlayer, move)) 
    {
        std::cout << "Illegal move!\n";
        return false;
    }
    
    // Execute the move
    board.executeMove(move);
    
    // Check for check/checkmate
    Color opponent = (currentPlayer == Color::WHITE) ? Color::BLACK : Color::WHITE;
    
    if (prolog.isCheckmate(board, opponent)) 
    {
        std::cout << "\n*** CHECKMATE! " 
                  << (currentPlayer == Color::WHITE ? "White" : "Black")
                  << " wins! ***\n";
        gameOver = true;
        return true;
    }
    
    if (prolog.isInCheck(board, opponent)) 
    {
        std::cout << "\n*** CHECK! ***\n";
    }
    
    return true;
}

// Main game loop
void Game::play() 
{
    std::cout << "\n";
    std::cout << "╔════════════════════════════════════════╗\n";
    std::cout << "║                                        ║\n";
    std::cout << "║     ♔ ♕  CHESS ENGINE  ♛ ♚             ║\n";
    std::cout << "║                                        ║\n";
    std::cout << "║        Multi-Paradigm Project          ║\n";
    std::cout << "║                                        ║\n";
    std::cout << "╚════════════════════════════════════════╝\n";
    std::cout << "\n";
    std::cout << "  Commands:\n";
    std::cout << "    • Move format: e2 e4 (or e2e4)\n";
    std::cout << "    • Type 'quit' or 'exit' to end\n";
    std::cout << "\n";
    
    while (!gameOver) 
    {
        board.display();
        displayStatus();
        
        Move move = getHumanMove();
        
        if (gameOver) break;
        
        if (makeMove(move)) 
        {
            switchPlayer();
        }
    }
    
    board.display();
    std::cout << "\n";
    std::cout << "╔════════════════════════════════════════╗\n";
    std::cout << "║           Thanks for playing!          ║\n";
    std::cout << "╚════════════════════════════════════════╝\n";
    std::cout << "\n";
}