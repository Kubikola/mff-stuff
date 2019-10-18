/*

DU12SEM.CPP

JY

Mlaskal's semantic interface for DU1-2

*/

// CHANGE THIS LINE TO #include "du3456sem.hpp" WHEN THIS FILE IS COPIED TO du3456sem.cpp
#include "du12sem.hpp"
#include "duerr.hpp"
#include <regex>

namespace mlc {

	using std::string;
	using std::tuple;
	using std::reverse;
	using std::make_tuple;
	using std::to_string;
	using std::regex;
	using std::smatch;
	
	string LexUtils::toUpperCase(const char *text)
	{
		string ret(text);
		transform(ret.begin(), ret.end(), ret.begin(), ::toupper);
		return ret;
	}

	tuple<int, bool> LexUtils::uint_parse(string const& num)
	{
		string bin = toBinary(num);
		bool ok = true;
		if(bin.size() > 31)
		{
			bin = bin.erase(0, bin.size() - 31);
			ok = false;
		}
		return make_tuple(stoi(bin, nullptr, 2), ok);
	}

	tuple<string, string> LexUtils::split_uint_identifier(const char* text, size_t len)
	{
		size_t i = 0;
		while(isdigit(text[i]))
			++i;
		
		string out_int(text, i);
		string out_id;
		for (size_t j = i; j < len; ++j)
			out_id += text[j];
		
		return make_tuple(out_int, out_id);
	}

	tuple<string, string> LexUtils::split_real_identifier(const char* text, size_t len)
	{
		string s(text);
		regex pattern(R"(([0-9]+\.[0-9]*[eE][\+\-]?[0-9]+|[0-9]+[eE][\+\-]?[0-9]+|[0-9]+\.[0-9]*)([a-zA-Z][a-zA-Z0-9]*))");
		smatch matches;
		regex_search(s, matches, pattern);
		return make_tuple(matches[1].str(), matches[2].str());
	}

	string LexUtils::toBinary(string const& num)
	{
		string c = num;
		string ret;
		while (c != "0")
		{
			auto [q, r] = longDivision(c, 2);
			ret += r;
			c = q;
		}
		reverse(ret.begin(), ret.end());
		return ret;
	}
	tuple<string, string> LexUtils::longDivision(string const& a, int q)
	{
		string z = "0";
		string b;
		string out;

		size_t j;
		for (j = 0; j < a.size(); ++j)
		{
			if (stoi(z + b) < q)
				b += a[j];
			else break;
		}

		for (size_t i = j; i < a.size(); ++i)
		{
			out += to_string(stoi(z + b) / q);
			z = to_string(stoi(z + b) % q);
			b = "";

			b += a[i];
		}
		out += to_string(stoi(z + b) / q);
		z = to_string(stoi(z + b) % q);
		return make_tuple(out, z);
	}
};

/*****************************************/