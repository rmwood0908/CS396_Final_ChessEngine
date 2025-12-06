#ifndef SCHEME_INTERFACE_H
#define SCHEME_INTERFACE_H

#include <string>
#include <vector>

// Handles communication with the Scheme-based AI player
class SchemeInterface
{
public:
    // Initializes the interface with the directory that contains ai.rkt
    explicit SchemeInterface(const std::string& schemeDir);

    // Chooses a move for the given color and board using the provided legal moves
    std::string chooseMove(const std::string& color,
                           const std::string& boardString,
                           const std::vector<std::string>& legalMoves) const;

private:
    // Directory path where the Scheme AI script is located
    std::string schemeDir;
};

#endif
