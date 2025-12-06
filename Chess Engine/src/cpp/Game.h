#ifndef GAME_H
#define GAME_H

#include "Board.h"
#include "PrologInterface.h"
#include "SchemeInterface.h"
#include <string>

class Game 
{
private:
    Board board;
    PrologInterface prolog;
    SchemeInterface scheme;
    Color currentPlayer;
    bool gameOver;
    
    // Input parsing
    Move parseMove(const std::string& input) const;
    bool isValidInput(const std::string& input) const;
    
    // Helper functions
    void switchPlayer();
    void displayStatus() const;
    
public:
    Game(const std::string& prologPath, const std::string& schemePath);
    
    // Main game loop
    void play();
    
    // Get move from human player
    Move getHumanMove();
    
    // Get move from AI
    Move getAIMove();
    
    // Process a move
    bool makeMove(const Move& move);
};

#endif // GAME_H
