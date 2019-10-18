/*

	DU12SEM.H

	DB

	Mlaskal's semantic interface for DU1-2

*/

#ifndef __DU12SEM_H
#define __DU12SEM_H

#include <string>
#include "literal_storage.hpp"
#include "flat_icblock.hpp"
#include "dutables.hpp"
#include "abstract_instr.hpp"
#include "gen_ainstr.hpp"
#include <tuple>

namespace mlc {

	class LexUtils
	{
	public:
		static std::string toUpperCase(const char *text);
		static std::tuple<int, bool> uint_parse(std::string const &num);
		static std::tuple<std::string, std::string> split_uint_identifier(const char *text, size_t len);
		static std::tuple<std::string, std::string> split_real_identifier(const char *text, size_t len);
	private:
		static std::string toBinary(std::string const &num);
		static std::tuple<std::string, std::string> longDivision(std::string const& a, int q);
	};

}

#endif
