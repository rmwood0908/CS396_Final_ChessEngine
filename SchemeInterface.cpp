// SchemeInterface.cpp
#include "SchemeInterface.h"

#include <array>
#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <memory>
#include <sstream>

// Stores the directory where the Scheme AI script lives
SchemeInterface::SchemeInterface(const std::string& schemeDir)
    : schemeDir(schemeDir)
{
}

// Runs a shell command and returns everything it prints to standard output
static std::string runCommand(const std::string& cmd)
{
    std::array<char, 256> buffer;
    std::string result;

    // Open a pipe to the external process
    std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd.c_str(), "r"), pclose);
    // If the process failed to start, return an empty string
    if (!pipe)
    {
        std::cerr << "Error: failed to run Scheme process\n";
        return "";
    }

    // Read until there is no more output from the process
    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr)
    {
        result += buffer.data();
    }
    // Return the collected output
    return result;
}

// Asks the Scheme AI to choose a move from a list of legal move strings
std::string SchemeInterface::chooseMove(const std::string& color,
                                        const std::string& boardString,
                                        const std::vector<std::string>& legalMoves) const
{
    // If there are no legal moves, return an empty string
    if (legalMoves.empty())
        return "";

    // Build the command that changes into the Scheme directory and runs the script
    std::ostringstream cmd;
    cmd << "cd " << schemeDir << " && ";
    cmd << "racket ai.rkt " << color << " " << boardString;

    // Append each legal move as an argument
    for (const auto& m : legalMoves)
        cmd << " " << m;

    // Redirect errors into standard output so everything is captured
    cmd << " 2>&1";

    // Run the command and capture the AI's output
    std::string output = runCommand(cmd.str());
    // If nothing came back, treat it as failure
    if (output.empty())
        return "";

    // Take the first whitespace-separated token as the chosen move
    std::istringstream iss(output);
    std::string move;
    iss >> move;
    return move;
}
