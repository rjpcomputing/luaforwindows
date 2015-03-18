#include "hello.hpp"

#include <iostream>

using namespace Hello;

std::string HelloWorld::say_hello_to(std::string name)
{
	std::string message("Hello " + name + "!");
	count++;
	if (!quiet) std::cout << message << std::endl;
	return message;
}

