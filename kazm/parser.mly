/* Ocamlyacc parser for Kazm */

%{
open Ast

let join_str_list str_list delimiter = List.fold_left (fun a b -> a ^ delimiter ^ b) "" (List.rev str_list)
let concat_stmts stmts = join_str_list stmts "\n"
let concat_list list = join_str_list list ", "
%}

%token PAREN_L PAREN_R BRACE_L BRACE_R SQB_L SQB_R SQB_PAIR /* ( ) { } [ ] */
%token DOT SEMI COMMA MOD ASSIGN  /* . ; , * % = */
%token PLUS MINUS TIMES DIVIDE  /* + - * / */
%token PLUSEQ MINUSEQ TIMESEQ DIVIDEQ /* + - * / += -= *= /= */
%token AND OR NOT  /* && || ! */
%token EQ NEQ LT LEQ GT GEQ /* == != < <= > >= */
%token VOID BOOL CHAR INT DOUBLE
%token IF ELSE FOR WHILE
%token RETURN BREAK
%token CLASS
%token TRUE FALSE

%token<string> IDENTIFIER
%token<string> STRING_LITERAL
%token<int> INT_LITERAL
%token EOF

%nonassoc NOELSE
%nonassoc ELSE
%nonassoc PAREN_L PAREN_R BRACE_L BRACE_R SQB_L SQB_R
%left SEMICO
%left IF
%right ASSIGN PLUSEQ MINUSEQ TIMESEQ DIVIDEQ
%left OR
%left AND
%left EQ NEQ
%left LT GT GEQ LEQ
%left PLUS MINUS
%left TIMES DIVIDE MOD
%right NOT

%left DOT

%start program
%type <Ast.program> program
%%

program:
    blocks EOF { Program(concat_stmts $1) }

blocks:
    blocks block { $2::$1 }
  | { [] }

block:
    func { $1 }
  | class_ { $1 }

class_:
    CLASS simple_name BRACE_L class_body BRACE_R SEMI { "decl'd class " ^ $2 ^ "\n body:\n" ^ concat_stmts $4 }

class_body:
    class_body func { $2::$1 }
  | class_body func_ctr { $2::$1 }
  | class_body decl_var_expr SEMI { $2::$1 }
  | { [] }

func:
    dtype_with_simple_name PAREN_L arg_list PAREN_R BRACE_L stmts BRACE_R {
      "function " ^ $1 ^ " with arg list " ^ (concat_list $3) ^ " and body: " ^ concat_stmts $6
    }

// constructor
func_ctr:
    simple_name PAREN_L arg_list PAREN_R BRACE_L stmts BRACE_R {
      "constructor function " ^ $1 ^ " with arg list " ^ (concat_list $3) ^ " and body: " ^ concat_stmts $6
    }


stmts:
    stmts stmt { $2::$1 }
  | { [] }

stmt:
    expr SEMI { $1 }
  | return_stmt SEMI { $1 }
  | break_stmt SEMI { $1 }
  | if_stmt { $1 }
  | while_stmt { $1 }
  | for_stmt { $1 }

return_stmt:
    RETURN expr { "Return: " ^ $2 }

break_stmt:
    BREAK { "Break." }

if_stmt:
    IF PAREN_L expr PAREN_R BRACE_L stmts BRACE_R ELSE BRACE_L stmts BRACE_R { "if with catch-all else" }
  | IF PAREN_L expr PAREN_R BRACE_L stmts BRACE_R ELSE if_stmt { "continuation if" }
  | IF PAREN_L expr PAREN_R BRACE_L stmts BRACE_R { "start of if" }

while_stmt:
    WHILE PAREN_L expr PAREN_R BRACE_L stmts BRACE_R { "while (" ^ $3 ^ ") {\n" ^ (concat_stmts $6) ^ "\n}" }

for_stmt:
    FOR PAREN_L expr SEMI expr SEMI expr PAREN_R BRACE_L stmts BRACE_R { "for (" ^ $3 ^"; " ^ $5 ^ "; " ^ $7 ^ ") {\n" ^ (concat_stmts $10) ^ "\n}" }

arg_list:
    { [] }
  | arg_list COMMA dtype_with_simple_name { $3::$1 }
  | dtype_with_simple_name { $1::[] }

expr:
    INT_LITERAL        { string_of_int $1 }
  | STRING_LITERAL     { "string_literal: " ^ $1 }
  | expr PLUS expr     { "(" ^ $1 ^ " + " ^ $3 ^ ")" }
  | expr MINUS expr    { "(" ^ $1 ^ " - " ^ $3 ^ ")" }
  | expr TIMES expr    { "(" ^ $1 ^ " * " ^ $3 ^ ")" }
  | expr DIVIDE expr   { "(" ^ $1 ^ " / " ^ $3 ^ ")" }
  | expr MOD expr      { "(" ^ $1 ^ " % " ^ $3 ^ ")" }
  | expr EQ expr       { "(" ^ $1 ^ " == " ^ $3 ^ ")" }
  | expr NEQ expr      { "(" ^ $1 ^ " != " ^ $3 ^ ")" }
  | expr LT expr       { "(" ^ $1 ^ " < " ^ $3 ^ ")" }
  | expr LEQ expr      { "(" ^ $1 ^ " <= " ^ $3 ^ ")" }
  | expr GT expr       { "(" ^ $1 ^ " > " ^ $3 ^ ")" }
  | expr GEQ expr      { "(" ^ $1 ^ " >= " ^ $3 ^ ")" }
  | expr AND expr      { "(" ^ $1 ^ " && " ^ $3 ^ ")" }
  | expr OR expr       { "(" ^ $1 ^ " || " ^ $3 ^ ")" }
  | NOT expr           { "(! " ^ $2 ^ ")" }
  | PAREN_L expr PAREN_R { "(" ^ $2 ^ ")" }
  | assign_new_var_expr { "(" ^ $1 ^ ")" }
  | assign_expr        { "(" ^ $1 ^ ")" }
  // call a function
  | full_name PAREN_L expr_list PAREN_R { "(calling " ^ $1 ^ " with expr_list " ^ (concat_list $3) ^ ")" }
  | array_element { $1 }
  // refer to a name
  | full_name          { "(" ^ $1 ^ ")" }
  | TRUE               { "true" }
  | FALSE              { "false" }

array_element:
  // array access
  | expr SQB_L expr SQB_R { "array access at pos " ^ $3 ^ " of " ^ $1 }

assign_expr:
    full_name_or_array_element ASSIGN expr   { $1 ^ " = " ^ $3 }
  | full_name_or_array_element PLUSEQ expr   { $1 ^ " += " ^ $3 }
  | full_name_or_array_element MINUSEQ expr  { $1 ^ " -= " ^ $3 }
  | full_name_or_array_element TIMESEQ expr  { $1 ^ " *= " ^ $3 }
  | full_name_or_array_element DIVIDEQ expr  { $1 ^ " /= " ^ $3 }

full_name_or_array_element:
    full_name { $1 }
  | array_element { $1 }

expr_list:
    { [] }
  | expr_list COMMA expr { $3::$1 }
  | expr { $1::[] }

decl_var_expr:
    dtype_with_simple_name { "declaring new var " ^ $1 }

assign_new_var_expr:
    dtype_with_simple_name ASSIGN expr { "assigning new var " ^ $3 ^ " to " ^ $1 }

dtype_with_simple_name:
    dtype simple_name { $2 ^ " (t: " ^ $1 ^ ")" }

full_name:
    expr DOT IDENTIFIER { $1 ^ "." ^ $3 }
  | IDENTIFIER { $1 }

simple_name:
    IDENTIFIER { $1 }

dtype:
    VOID { "void" }
  | singular_type { $1 }
  // arrays
  | singular_type SQB_PAIR { "array of " ^ $1 }

singular_type:
  // primitives
    BOOL { "bool" }
  | CHAR { "char" }
  | INT { "int" }
  | DOUBLE { "double" }
  // user-defined
  | IDENTIFIER { "custom dtype:" ^ $1 }
