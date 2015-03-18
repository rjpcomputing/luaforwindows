#ifndef HELLO_H
#define HELLO_H

#include <string>

namespace Hello {
	
	class HelloWorld {
		bool quiet;
		long count;
	public:
		HelloWorld(bool isquiet) : quiet(isquiet), count(0) {};
		void _set_quiet(bool value) { quiet = value; };
		bool _get_quiet()           { return quiet; };
		long _get_count()           { return count; };
		std::string say_hello_to(std::string name);
	};

};

#endif /* HELLO_H */
