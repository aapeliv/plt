/* Ocamlyacc parser for Kazm */
%{
open Ast
%}

%token PAREN_L PAREN_R BRACE_L BRACE_R 
%token SQB_L SQB_R /* ( ) { } [ ] */
%token DOT SEMI COMMA MOD ASSIGN  /* . ; , * % = */
%token PLUS MINUS TIMES DIVIDE  /* + - * / */
%token PLUSEQ MINUSEQ TIMESEQ DIVIDEQ /* + - * / += -= *= /= */
%token AND OR NOT  /* && || ! */
%token EQ NEQ LT LEQ GT GEQ /* == != < <= > >= */
%token VOID BOOL CHAR INT DOUBLE STRING 
%token ARRAY 
%token IF ELSE FOR WHILE
%token RETURN BREAK
%token CLASS 
%token TRUE FALSE
/* %token LENGTH  */

%token<string> IDENTIFIER CLASS_IDENTIFIER 
%token<string> CLASS_NAME
%token<string> STRING_LITERAL
%token<float> DOUBLE_LITERAL
%token<char> CHAR_LITERAL
%token<int> INT_LITERAL
%token EOF

%nonassoc NOELSE
%nonassoc ELSE
%nonassoc BRACE_L BRACE_R 
%left SEMI
%left IF
%right ASSIGN PLUSEQ MINUSEQ TIMESEQ DIVIDEQ
%left OR
%left AND
%left EQ NEQ
%left LT GT GEQ LEQ
%left PLUS MINUS
%left TIMES DIVIDE MOD
%right NOT
%left SQB_L SQB_R
%left PAREN_L PAREN_R

%left DOT

%start program
%type <Ast.program> program
%%

program:
  decls EOF { $1 }

decls:
   /* nothing */ { ([], [], []) }
 | decls var_decl {
   let (f, s, t) = $1 in
   (f @ [$2], s, t)
  }
 | decls fdecl {
   let (f, s, t) = $1 in
   (f, s @ [$2], t)
  }
 | decls cdecl {
   let (f, s, t) = $1 in
   (f, s, t @ [$2])
 }

fdecl:
   typ IDENTIFIER PAREN_L formals_opt PAREN_R BRACE_L var_decls stmts BRACE_R
     { { typ = $1;
         fname = $2;
         formals = List.rev $4;
         locals = List.rev $7;
         body = List.rev $8 } }

cdecl:
    CLASS CLASS_IDENTIFIER BRACE_L class_body BRACE_R SEMI { { cname = $2; cvars = $4 } }

class_body:
    var_decls { $1 }

formals_opt:
    /* nothing */ { [] }
  | formal_list   { $1 }

/* doesnt have a type yet */
// constructor:
//   CLASS_IDENTIFIER PAREN_L formals_opt PAREN_R BRACE_L var_decls stmts BRACE_R { {
//       fname = $1;
//       formals = List.rev $3;
//       locals = List.rev $6;
//       body = List.rev $7 } } 

formal_list:
    typ IDENTIFIER { [($1,$2)] }
  | formal_list COMMA typ IDENTIFIER { ($3,$4) :: $1 }

typ:
    VOID { Void }
  | BOOL { Bool }
  | CHAR { Char }
  | INT { Int }
  | DOUBLE { Double }
  | STRING { String }
  | atyp { $1 } // 
  | CLASS_IDENTIFIER { ClassT($1) }

atyp:
    ARRAY typ SQB_L INT_LITERAL SQB_R { ArrayT($2, $4) } 

var_decls:
    { [] }
  | var_decls var_decl { $2 :: $1 }

var_decl:
    typ IDENTIFIER SEMI { ($1, $2) }

stmts:
    { [] }
  | stmts stmt { $2::$1 }

stmt:
    expr SEMI { Expr $1 }
  | return_stmt SEMI { $1 }
  | break_stmt SEMI { $1 }
  | if_stmt { $1 }
  | while_stmt { $1 }
  | for_stmt { $1 }

block_stmt:
    BRACE_L stmts BRACE_R { Block(List.rev $2) }

return_stmt:
    RETURN expr { Return $2 }
  | RETURN { EmptyReturn }

break_stmt:
    BREAK { Break }

if_stmt:
    IF PAREN_L expr PAREN_R BRACE_L stmts BRACE_R ELSE BRACE_L stmts BRACE_R { If($3, Block(List.rev $6), Block(List.rev $10)) }
  | IF PAREN_L expr PAREN_R BRACE_L stmts BRACE_R { If($3, Block(List.rev $6), Block([])) }

while_stmt:
    WHILE PAREN_L expr PAREN_R BRACE_L stmts BRACE_R { While($3, Block(List.rev $6)) }

for_stmt:
    FOR PAREN_L expr SEMI expr SEMI expr PAREN_R BRACE_L stmts BRACE_R { For($3, $5, $7, Block(List.rev $10)) }

expr:
    INT_LITERAL        { Literal($1) }
  | STRING_LITERAL     { StringLit($1) }
  | DOUBLE_LITERAL     { Dliteral(string_of_float $1)}
  | CHAR_LITERAL       { CharLit(Char.escaped $1)}
  | TRUE               { BoolLit(true) }
  | FALSE              { BoolLit(false) }
  | expr PLUS   expr   { Binop($1, Add,   $3)   }
  | expr MINUS  expr   { Binop($1, Sub,   $3)   }
  | expr TIMES  expr   { Binop($1, Mult,  $3)   }
  | expr DIVIDE expr   { Binop($1, Div,   $3)   }
  | expr MOD expr      { Binop($1, Mod,   $3)   }
  | expr EQ     expr   { Binop($1, Equal, $3)   }
  | expr NEQ    expr   { Binop($1, Neq,   $3)   }
  | expr LT     expr   { Binop($1, Less,  $3)   }
  | expr LEQ    expr   { Binop($1, Leq,   $3)   }
  | expr GT     expr   { Binop($1, Greater, $3) }
  | expr GEQ    expr   { Binop($1, Geq,   $3)   }
  | expr AND    expr   { Binop($1, And,   $3)   }
  | expr OR     expr   { Binop($1, Or,    $3)   }
  | NOT expr           { Unop(Not, $2) }
  | PAREN_L expr PAREN_R { $2 }
  | atyp IDENTIFIER ASSIGN SQB_L array_opt SQB_R { ArrayExp($1, $2, (List.rev $5))}
  | fq_identifier ASSIGN expr { Assign($1, $3) } 
  | IDENTIFIER PAREN_L args_opt PAREN_R { Call($1, $3) }
  | fq_identifier      { Id($1) }
  | typ SQB_L expr SQB_R IDENTIFIER {ArrayDecl($1, $3, $5)} 
  | SQB_L array_opt SQB_R          { ArrayLit(List.rev $2) } 
  | fq_identifier SQB_L expr SQB_R ASSIGN expr {ArrayAssign(Id($1), $3, $6)}
  | fq_identifier SQB_L expr SQB_R {ArrayIndex(Id($1), $3)} 
  /* | fq_identifier DOT LENGTH { ArrayLength($1) } */
  /* | atyp IDENTIFIER ASSIGN SQB_L array_opt SQB_R { ArrayExp($1, $2, (List.rev $5))} */

fq_identifier:
    IDENTIFIER { [$1] }
  | IDENTIFIER DOT IDENTIFIER { $1::$3::[] }

array_opt:
    { [] } 
  | expr { [$1] }
  | array_opt COMMA expr { $3 :: $1 }
// can look like [0.0], [1, 2, 3], etc. 

args_opt:
    /* nothing */ { [] }
  | args_list     { List.rev $1 }

args_list:
    expr                    { [$1] }
  | args_list COMMA expr { $3 :: $1 }

expr_list:
    { [] }
  | expr_list COMMA expr { $3::$1 }
  | expr { $1::[] }