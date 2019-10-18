%{
	// this code is emitted into du12l.cpp 
	// avoid macro redefinition warnings when compiling du1l.cpp
	#pragma warning (disable:4005)
	// avoid unreferenced parameter warnings when compiling du1l.cpp
	#pragma warning (disable:4100)
	// avoid unreferenced function warnings when compiling du1l.cpp
	#pragma warning (disable:4505)

	// allow access to YY_DECL macro
	#include "bisonflex.hpp"

	// allow access to context 
	// CHANGE THIS LINE TO #include "du3456g.hpp" WHEN THIS FILE IS COPIED TO du3456l.lex
	#include "dummyg.hpp"

	//necessary for calling C++ routines for du2
	#include "du12sem.hpp"

	#include <string>
%}

%x comment
%x str
%x array

/* DO NOT TOUCH THIS OPTIONS! */
%option noyywrap nounput batch noinput stack reentrant
%option never-interactive

WHITESPACE [ \r\t\f]
IDENTIFIER [a-zA-Z][a-zA-Z0-9]*
DIGIT [0-9]
PM [+-]

REAL {DIGIT}+"."{DIGIT}*(?i:e){PM}?{DIGIT}+|{DIGIT}+(?i:e){PM}?{DIGIT}+|{DIGIT}+"."{DIGIT}*
UINT {DIGIT}+ 

%%

%{
	typedef yy::mlaskal_parser parser;

	using std::atoi;
	using std::stod;
	using std::string;
	using std::out_of_range;

	int brackets_balance = 0;

	string text;
%}

<comment,INITIAL>"{" {
	++brackets_balance;
	BEGIN(comment);
}

<comment>"}" {
	--brackets_balance;
	if(!brackets_balance) 
		BEGIN(INITIAL);
}

<comment><<EOF>> {
	message(mlc::err_code::DUERR_EOFINCMT, ctx->curline);
	return parser::make_EOF(ctx->curline);
}

<str>"''" {
	text += "'";
}

<INITIAL>"'" {
	BEGIN(str);
	text = "";
}

<str>"'" {
	BEGIN(INITIAL);
	return parser::make_STRING(ctx->tab->ls_str().add(text), ctx->curline);
}

<str>"\n" {
	message(mlc::err_code::DUERR_EOLINSTRCHR, ctx->curline);	
	BEGIN(INITIAL);
	return parser::make_STRING(ctx->tab->ls_str().add(text), ctx->curline++);

}

<str><<EOF>> {
	message(mlc::err_code::DUERR_EOFINSTRCHR, ctx->curline);
	return parser::make_EOF(ctx->curline);
}

<str>. {
	text += yytext;
}

<comment>. 

"}" {
	message(mlc::DUERR_UNEXPENDCMT, ctx->curline);
}

<INITIAL>{REAL}{IDENTIFIER} {
	auto [m, _] = mlc::LexUtils::split_real_identifier(yytext, yyleng);
	message(mlc::err_code::DUERR_BADREAL, ctx->curline, yytext);
	double d;
	try {
		d = stod(yytext);
	}
	catch(out_of_range const &) {
		message(mlc::err_code::DUERR_REALOUTRANGE, ctx->curline, yytext);
	}
	return parser::make_REAL(ctx->tab->ls_real().add(d), ctx->curline);
}

<INITIAL,array>{UINT}{IDENTIFIER} {
	auto [m, _] = mlc::LexUtils::split_uint_identifier(yytext, yyleng);
	message(mlc::err_code::DUERR_BADINT, ctx->curline, yytext);

	auto [n, ok] = mlc::LexUtils::uint_parse(m);
	if(!ok) 
		message(mlc::err_code::DUERR_INTOUTRANGE, ctx->curline, yytext);

	return parser::make_UINT(ctx->tab->ls_int().add(n), ctx->curline);
}

{REAL} {
	double d;
	try {
		d = stod(yytext);
	}
	catch(out_of_range const &) {
		message(mlc::err_code::DUERR_REALOUTRANGE, ctx->curline, yytext);
	}
	return parser::make_REAL(ctx->tab->ls_real().add(d), ctx->curline);
}

<INITIAL,array>{UINT} {
			    auto [n, ok] = mlc::LexUtils::uint_parse(yytext);
				if(!ok) 
					message(mlc::err_code::DUERR_INTOUTRANGE, ctx->curline, yytext);

			    return parser::make_UINT(ctx->tab->ls_int().add(n), ctx->curline);
			}

<array>".." {
	return parser::make_DOTDOT(ctx->curline);
}

";" {
		return parser::make_SEMICOLON(ctx->curline);
	}

(?i:program) {	
				return parser::make_PROGRAM(ctx->curline);
			}

(?i:label) {
		return parser::make_LABEL(ctx->curline);
}

(?i:type) {
	return parser::make_TYPE(ctx->curline);
}

"=" {
	return parser::make_EQ(ctx->curline);
}

":=" {
	return parser::make_ASSIGN(ctx->curline);
}

":" {
	return parser::make_COLON(ctx->curline);
}

"," {
	return parser::make_COMMA(ctx->curline);
}

"(" {
	return parser::make_LPAR(ctx->curline);
}

")" {
	return parser::make_RPAR(ctx->curline);
}

(?i:if) {
	return parser::make_IF(ctx->curline);
}

(?i:then) {
	return parser::make_THEN(ctx->curline);
}

(?i:else) {
	return parser::make_ELSE(ctx->curline);
}

(?i:goto) {
	return parser::make_GOTO(ctx->curline);
}

(?i:begin) {
	return parser::make_BEGIN(ctx->curline);
}

(?i:end) {
	return parser::make_END(ctx->curline);
}

"." {
	return parser::make_DOT(ctx->curline);
}

(?i:array) {
	return parser::make_ARRAY(ctx->curline);
}

(?i:const) {
	return parser::make_CONST(ctx->curline);
}

(?i:do) {
	return parser::make_DO(ctx->curline);
}

(?i:for) {
	return parser::make_FOR(ctx->curline);
}

(?i:function) {
	return parser::make_FUNCTION(ctx->curline);
}

(?i:while) {
	return parser::make_WHILE(ctx->curline);
}

(?i:var) {
	return parser::make_VAR(ctx->curline);
}

(?i:until) {
	return parser::make_UNTIL(ctx->curline);
}

(?i:repeat) {
	return parser::make_REPEAT(ctx->curline);
}

(?i:record) {
	return parser::make_RECORD(ctx->curline);
}

"[" {
	BEGIN(array);
	return parser::make_LSBRA(ctx->curline);
}

<array>"]" {
	BEGIN(INITIAL);
	return parser::make_RSBRA(ctx->curline);
}

(?i:procedure) {
	return parser::make_PROCEDURE(ctx->curline);
}

(?i:or) {
	return parser::make_OR(ctx->curline);
}

(?i:of) {
	return parser::make_OF(ctx->curline);
}

(?i:not) {
	return parser::make_NOT(ctx->curline);
}

">=" {
	return parser::make_OPER_REL(mlc::DUTOKGE_OPER_REL::DUTOKGE_GE, ctx->curline);
	}
">" {
	return parser::make_OPER_REL(mlc::DUTOKGE_OPER_REL::DUTOKGE_GT, ctx->curline);
}
"<=" {
	return parser::make_OPER_REL(mlc::DUTOKGE_OPER_REL::DUTOKGE_LE, ctx->curline);
}

"<" {
	return parser::make_OPER_REL(mlc::DUTOKGE_OPER_REL::DUTOKGE_LT, ctx->curline);
	}
"<>" {
	return parser::make_OPER_REL(mlc::DUTOKGE_OPER_REL::DUTOKGE_NE, ctx->curline);
}

(?i:and) {
	return parser::make_OPER_MUL(mlc::DUTOKGE_OPER_MUL::DUTOKGE_AND, ctx->curline);
}
"*" {
	return parser::make_OPER_MUL(mlc::DUTOKGE_OPER_MUL::DUTOKGE_ASTERISK, ctx->curline);
}

(?i:div) {
	return parser::make_OPER_MUL(mlc::DUTOKGE_OPER_MUL::DUTOKGE_DIV, ctx->curline);
}

(?i:mod) {
	return parser::make_OPER_MUL(mlc::DUTOKGE_OPER_MUL::DUTOKGE_MOD, ctx->curline);
}

"/" {
	return parser::make_OPER_MUL(mlc::DUTOKGE_OPER_MUL::DUTOKGE_SOLIDUS, ctx->curline);
}

"-" {
	return parser::make_OPER_SIGNADD(mlc::DUTOKGE_OPER_SIGNADD::DUTOKGE_MINUS, ctx->curline);
}

"+" {
	return parser::make_OPER_SIGNADD(mlc::DUTOKGE_OPER_SIGNADD::DUTOKGE_PLUS, ctx->curline);
}

(?i:to) {
	return parser::make_FOR_DIRECTION(mlc::DUTOKGE_FOR_DIRECTION::DUTOKGE_TO, ctx->curline);
}

(?i:downto) {
	return parser::make_FOR_DIRECTION(mlc::DUTOKGE_FOR_DIRECTION::DUTOKGE_DOWNTO, ctx->curline);
}

{IDENTIFIER} {
		       string id_upC = mlc::LexUtils::toUpperCase(yytext);
			   return parser::make_IDENTIFIER(ctx->tab->ls_id().add(id_upC), ctx->curline);
	       }

<INITIAL,comment,array>{WHITESPACE}+		/* go out with whitespaces */

<INITIAL,comment,array>"\n" {
	++ctx->curline;
}

.			message(mlc::DUERR_UNKCHAR, ctx->curline, *yytext, *yytext);

<<EOF>>		return parser::make_EOF(ctx->curline);

%%

namespace mlc {

	yyscan_t2 lexer_init(FILE * iff)
	{
		yyscan_t2 scanner;
		yylex_init(&scanner);
		yyset_in(iff, scanner);
		return scanner;
	}

	void lexer_shutdown(yyscan_t2 scanner)
	{
		yyset_in(nullptr, scanner);
		yylex_destroy(scanner);
	}

}
