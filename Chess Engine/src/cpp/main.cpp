#include "Game.h"
#include <iostream>

int main() 
{
    try 
    {
        Game game("../prolog", "../scheme");
        game.play();
    }
    catch (const std::exception& e) 
    {
        std::cerr << "Error: " << e.what() << "\n";
        return 1;
    }
    
    return 0;
}
