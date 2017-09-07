%top{
#include <stdio.h>
#include <string>
#include <vector>
#include <unordered_map>
#include <iostream>
#include <algorithm>

#define lastchar yytext[yyleng - 1]
#define YY_BUF_SIZE 66000

std::vector<char> alphabet;
std::vector<char> symbols;
std::unordered_map<char, std::vector<std::string> > my_rules;
char head_rule;
std::string rule;
char start_symbol;
std::vector<char> marked;
std::vector<char> marked_value;
int to_mark;
int syntax_err = 0, semantic_err = 0;

void add_rule(char, std::string, int);
void create_entrance(char);
void useless_terminals();
bool contains_nonterm(std::string);
void print_void();
void print_useless();
bool only_nonterminals();
bool start_validation();
bool terminals_validation();
bool rule_validation();
}

%s START_SYMBOLS SYMBOLS SEPARATOR1 SEPARATOR_SET1 ALPHABET START_ALPHABET NEXT_ALPHABET SEPARATOR_FOR_ALPHA REPLACEMENT RULES START_RULES SEPARATOR_SET2 SEPARATOR_SET3 START_SYMBOL SEP_VALUES SEP_RULES STOP REPL_CONT SEP_E NONTERMINALS NONTERMINALS2

lower_case_letter [a-d]|[f-z]
upper_case_letter [A-Z]
other "'"|"-"|"="|"["|"]"|";"|"`"|"\\"|"."|"/"|"~"|"!"|"@"|"#"|"$"|"%"|"^"|"&"|"*"|"_"|"+"|":"|"\""|"|"|"<"|">"|"?"
digit [0-9]
terminal {lower_case_letter}|{other}|{digit}
nonterminal {upper_case_letter}

%option noinput
%option nounput
%option noyymore
%%

[ \t\r\n] 

<INITIAL>"(" {
    BEGIN(START_SYMBOLS);
}
<START_SYMBOLS>"{" {
	BEGIN(SYMBOLS);
}
<SYMBOLS>{  
		{terminal} {
			symbols.push_back(lastchar);
			BEGIN(SEPARATOR1);
		}
		{nonterminal} {
			symbols.push_back(lastchar);
			BEGIN(SEPARATOR1);
		}
}
<SEPARATOR1>{
    "," BEGIN(SYMBOLS);
    "}" BEGIN(SEPARATOR_SET1);
}
<SEPARATOR_SET1>"," BEGIN(START_ALPHABET);
<START_ALPHABET>{
		"{" BEGIN(NEXT_ALPHABET);
}
<NEXT_ALPHABET>{
		"}" BEGIN(SEPARATOR_SET2);
		{terminal} {
				alphabet.push_back(lastchar);
				BEGIN(SEPARATOR_FOR_ALPHA);
		  }
}
<ALPHABET>{
		{terminal} {
			 alphabet.push_back(lastchar);
			 BEGIN(SEPARATOR_FOR_ALPHA);
		}
	}
<SEPARATOR_FOR_ALPHA>{
		"," BEGIN(ALPHABET);
		"}" BEGIN(SEPARATOR_SET2);
}		
<SEPARATOR_SET2>"," BEGIN(START_RULES);
<START_RULES>"{" BEGIN(RULES);
<RULES>{
	"}" BEGIN(SEPARATOR_SET3);
	"(" BEGIN(NONTERMINALS2);
}
<NONTERMINALS>"(" BEGIN(NONTERMINALS2);
<NONTERMINALS2>{nonterminal} {
				head_rule = lastchar;
				create_entrance(head_rule);
				rule = "";
				BEGIN(SEP_VALUES);
}
<SEP_VALUES>{
	"," {
		BEGIN(REPLACEMENT);
		to_mark = 1;
	}
}
<REPLACEMENT>{
	"e" {
		rule = "e";
		marked.push_back(head_rule);
		marked_value.push_back('e');
		BEGIN(SEP_E);
		}
	{terminal} {
		rule += lastchar;
		BEGIN(REPL_CONT);
	}
	{nonterminal} {
		rule += lastchar;
		to_mark = 0;
		BEGIN(REPL_CONT);
	}
}
<SEP_E>{
		")" {
			add_rule(head_rule, rule, to_mark);
			BEGIN(SEP_RULES);
		}
}
<REPL_CONT>{
		{terminal} {
			rule += lastchar;
			BEGIN(REPL_CONT);
		}
		{nonterminal} {
			rule += lastchar;
			to_mark = 0;
			BEGIN(REPL_CONT);
		}
		")" {
			add_rule(head_rule, rule, to_mark);
			BEGIN(SEP_RULES);
		}
}
<SEP_RULES>{
	"," {
		BEGIN(NONTERMINALS);
	}
	"}" {
	 	BEGIN(SEPARATOR_SET3);
	}
}
<SEPARATOR_SET3>"," BEGIN(START_SYMBOL);
<START_SYMBOL>{
			{nonterminal} {
				start_symbol = lastchar;
				BEGIN(STOP);
			}
			
}
<STOP>")"
. {		
	syntax_err = 1;
}
%%
/* Add rule for nonterminal in its vector of rules and add it in a
vector of marked nonterminals if its derivation leads to a string of terminals*/
void add_rule(char head, std::string rule, int to_mark){
	my_rules[head].push_back(rule);
	if(to_mark == 1){
		marked.push_back(head);
		marked_value.push_back(rule[0]);
	}	
}

/* If a nonterminal still  doesn't have any rule defined and we know there
is a rule for it, we create an empty vector and add it in the map with that
nonterminal as key */
void create_entrance(char head){
	if(my_rules.find(head) == my_rules.end()){
		std::vector<std::string> entrance;
		my_rules.insert(make_pair(head, entrance));
	}
}

/* Check if a string contains a nonterminal */
bool contains_nonterm(std::string my_string){
	for(int i = 0; i < my_string.size(); i++)
		if(my_string[i] <= 'Z' && my_string[i] >= 'A')
			return true;
	return false;
}

/* For every marked nonterminal we iterate through all rules and replace that 
marked nonterminals with the string associated. After every replacement, we check
if that rule still contains nonterminals in order to add the corresponding key 
to the marked list. We stop when all marked nonterminals were replaced. */
void useless_terminals(){	
	int i = 0;
	while(i < marked.size()){
		for(auto it : my_rules){
			std::vector<std::string> current_rules = it.second;
			if(std::find(marked.begin(), marked.end(), it.first)
												 == marked.end()){
				for(int j = 0; j < (current_rules).size(); j++){
					std::replace(current_rules[j].begin(), current_rules[j].end(),
													 marked[i], marked_value[i]);
					if(contains_nonterm(current_rules[j]) == false){
						marked.push_back(it.first);
						marked_value.push_back(current_rules[j][0]);
						break;
					}
				}
				my_rules[it.first] = current_rules;
			}
		}
		i++;
	}
}

/* For every symbol from the list we check if it is a nonterminal(we can't
find it in the alphabet) and if it is marked. */
void print_useless(){
	
	for(int k = 0; k < symbols.size(); k++)
		if(std::find(marked.begin(), marked.end(), symbols[k])
										 == marked.end() &&
					std::find(alphabet.begin(), alphabet.end(), 
										symbols[k]) == alphabet.end())
			std::cout << symbols[k] <<"\n";
}

/* We check if the start symbol in a marked nonterminal which means its
derivation leads to a string of terminals, so the grammar isn't void */
void print_void(){
	if(std::find(marked.begin(), marked.end(), start_symbol) == marked.end())
		std::cout << "Yes";
	else
		std::cout << "No";
}

/* If the start symbol is marked we check if there's a rule which contains only 'e';
if there's even only one rule, then the grammar has void symbol */
void print_has_void(){
	if(std::find(marked.begin(), marked.end(), start_symbol) == marked.end())
		std::cout << "No";
	else{
		int has_e;
		std::vector<std::string> start_rules = my_rules[start_symbol];
		for(int i = 0 ; i < start_rules.size(); i++){
			has_e = 1;
			for(int j = 0; j < start_rules[i].size(); j++){
				if(start_rules[i][j] != 'e'){
					has_e = 0;
					break;
				}
			}
			if(has_e == 1){
				std::cout << "Yes";
				return;
			}
		}
		std::cout <<"No";
	}
}

/* First we check if the rule has associated a nonterminal(it is a member of
the symbols list) the if the rules have elements only from the symbols list*/
bool rule_validation(){
	for(auto it : my_rules){
		if((it.first < 'A' || it.first > 'Z') || (std::find(symbols.begin(), 
									symbols.end(), it.first) == symbols.end()))
			return false;
		else{
			for(int j = 0; j < it.second.size(); j++){
				std::string rule = it.second[j];
				for(int k = 0; k < rule.size(); k++)
					if(rule[k] != 'e' && std::find(symbols.begin(), symbols.end(),
											 rule[k]) == symbols.end())
						return false;
			}
		}
	}
	return true;
}

/* Check if the alphabet is included in symbols list  */
bool terminals_validation(){
	for(int i = 0; i < alphabet.size(); i++)
		if(std::find(symbols.begin(), symbols.end(), alphabet[i]) 
												== symbols.end())
			return false;
	return true;
}

/* Check if the terminals from the sybols list are among the alphabet
elements */
bool only_nonterminals(){
	for(int i = 0; i < symbols.size(); i++){
		if(symbols[i] < 'A' || symbols[i] > 'Z')
			if(std::find(alphabet.begin(), alphabet.end(), 
								symbols[i]) == alphabet.end())
				return false;
	}
	return true;
}

/* Check if the start symbol is a nonterminal from symbols list */
bool start_validation(){
	if(start_symbol <= 'Z' && start_symbol >= 'A' && 
			std::find(symbols.begin(), symbols.end(), start_symbol) 
												!= symbols.end())
		return true;
	return false;
}

/* Check if there are problems with arguments, then if we met syntax errors
then if there are semantic errors and in case there's not any type of error
we proceed to respond to the question from the argument */
int main(int argc, char** argv)
{
    FILE* f = fopen("grammar", "rt");
    yyrestart(f);
    yylex();

	if(argc != 2)
		fprintf(stderr, "Argument error");
	else{
		if(strstr(argv[1], "--useless-nonterminals") == NULL &&
				strstr(argv[1], "--is-void") == NULL &&
				strstr(argv[1], "--has-e") == NULL)
			fprintf(stderr, "Argument error");
		else{
			if(syntax_err == 1)
				fprintf(stderr, "Syntax error");
			else{
				if(terminals_validation() == true && only_nonterminals() == true &&
					start_validation() == true && rule_validation() == true){ 
					if(strstr(argv[1], "useless") != NULL){
						useless_terminals();
						print_useless();
					}
					if(strstr(argv[1], "void") != NULL){
						useless_terminals();
						print_void();
					}
					if(strstr(argv[1], "has") != NULL){
						useless_terminals();
						print_has_void();
					}
				}
				else{
					fprintf(stderr, "Semantic error");
				}
			}
		}
	}
    fclose(f);
    return 0;
}
