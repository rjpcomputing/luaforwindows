// build@ g++  -g test1.cpp -o test1
#include <iostream>
#include <string>
using namespace std;

struct Pair {
	string first;
	string second;
	
	Pair(string s1, string s2)
		: first(s1), second(s2)
	{}
};

void one(string s1, string s2)
{
	int *pi = NULL;
	//~ *pi = 0;
	string s = s1 + s2;
	Pair pp(s1,s2);
	cout << s << endl;
}

void two(string s)
{
	string t = "help";
	one(s,t);
}

int main(int argc, char **argv)
{
	for(int i = 0; i < argc; i++)
		cout << argv[i] << endl;
	two("hello");
	//~ char ch;
	//~ cin >> ch;
	return 0;
}
