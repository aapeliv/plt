/* Ocamlyacc parser for Kazm */
%{
open Ast
%}

%token PAREN_L PAREN_R BRACE_L BRACE_R SQB_L SQB_R SQB_PAIR /* ( ) { } [ ] */
%token DOT SEMI COMMA MOD ASSIGN  /* . ; , * % = */
%token PLUS MINUS TIMES DIVIDE  /* + - * / */
%token PLUSEQ MINUSEQ TIMESEQ DIVIDEQ /* + - * / += -= *= /= */
%token AND OR NOT  /* && || ! */
%token EQ NEQ LT LEQ GT GEQ /* == != < <= > >= */
%token VOID BOOL CHAR INT DOUBLE STRING
%token IF ELSE FOR WHILE
%token RETURN BREAK
%token CLASS
%token TRUE FALSE

%token<string> IDENTIFIER
%token<string> STRING_LITERAL
%token<float> DOUBLE_LITERAL
%token<char> CHAR_LITERAL
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
  decls EOF { $1 }

decls:
   /* nothing */ { ([], []) }
 | decls vdecl { ((fst $1 @ [$2]), snd $1) }
 | decls fdecl { (fst $1, (snd $1 @ [$2])) }

fdecl:
   typ IDENTIFIER PAREN_L formals_opt PAREN_R BRACE_L vdecl_list stmts BRACE_R
     { { typ = $1;
         fname = $2;
         formals = List.rev $4;
         locals = List.rev $7;
         body = List.rev $8 } }

formals_opt:
    /* nothing */ { [] }
  | formal_list   { $1 }

formal_list:
    typ IDENTIFIER                    { [($1,$2)]     }
  | formal_list COMMA typ IDENTIFIER { ($3,$4) :: $1 }

typ:
    VOID { Void }
  | BOOL { Bool }
  | CHAR { Char }
  | INT { Int }
  | DOUBLE { Double }
  | STRING { String }

vdecl_list:
    /* nothing */    { [] }
  | vdecl_list vdecl { $2 :: $1 }

vdecl:
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
  | IDENTIFIER ASSIGN expr { Assign($1, $3) }
  | IDENTIFIER PAREN_L args_opt PAREN_R { Call($1, $3) }
  | IDENTIFIER          { Id($1) }

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

