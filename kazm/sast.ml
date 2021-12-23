(* Semantically-checked AST and functions for printing it *)

open Ast

type sref = (typ * string) list

type sexpr = typ * sx
and sx =
    SLiteral of int
  | SDliteral of string
  | SBoolLit of bool
  | SCharLit of string
  | SStringLit of string
  | SId of sref
  | SBinop of sexpr * op * sexpr
  | SUnop of uop * sexpr
  | SAssign of sref * sexpr
  | SCall of string * sexpr list
  | SNoexpr
  | SArrayAssign of sexpr * sexpr * sexpr
  | SArrayLit of sexpr list
  | SArrayIndex of sexpr * sexpr
  | SArrayDecl of typ * sexpr * string
  | SArrayExp of typ * string * sexpr list

type sstmt =
    SBlock of sstmt list
  | SExpr of sexpr
  | SReturn of sexpr
  | SIf of sexpr * sstmt * sstmt
  | SFor of sexpr * sexpr * sexpr * sstmt
  | SWhile of sexpr * sstmt
  | SBreak
  | SEmptyReturn


type sfunc_decl = {
    styp : typ;
    sfname : string;
    sformals : bind list;
    slocals : bind list;
    sbody : sstmt list;
}

type sclass_decl = {
    scname : class_t;
    scvars : bind list;
}

(* Pretty-printing functions *)

let rec string_of_sexpr (t, e) =
  "(" ^ string_of_typ t ^ " : " ^ (match e with
    SLiteral(l) -> string_of_int l
  | SBoolLit(true) -> "true"
  | SBoolLit(false) -> "false"
  | SCharLit c -> "\'" ^ c ^ "\'"
  | SStringLit s -> "\"" ^ s ^ "\""
  | SDliteral(l) -> l
  (* | SId(s) -> String.concat ", " s *)
  | SBinop(e1, o, e2) ->
      string_of_sexpr e1 ^ " " ^ string_of_op o ^ " " ^ string_of_sexpr e2
  | SUnop(o, e) -> string_of_uop o ^ string_of_sexpr e
  (* | SAssign(v, e) -> v ^ " = " ^ string_of_sexpr e *)
  | SCall(f, el) ->
      f ^ "(" ^ String.concat ", " (List.map string_of_sexpr el) ^ ")"
  | SArrayAssign(id, idx, v) -> string_of_sexpr id ^ "[" ^ string_of_sexpr idx ^"] = " ^ string_of_sexpr v
  | SArrayLit(l) -> "[" ^ (String.concat ", " (List.map string_of_sexpr l)) ^ "]"
  | SArrayIndex(id, idx) -> string_of_sexpr id ^ "[" ^ string_of_sexpr idx ^ "]"
  | SArrayDecl(t, idx, id) -> string_of_typ t ^ "[" ^ string_of_sexpr idx ^ "] " ^ id
  | SArrayExp(ty, str, exp) -> "ArrayExp;"
  | SNoexpr -> ""
                  ) ^ ")"

let rec string_of_sstmt = function
    SBlock(stmts) ->
      "{\n" ^ String.concat "" (List.map string_of_sstmt stmts) ^ "}\n"
  | SExpr(expr) -> string_of_sexpr expr ^ ";\n";
  | SReturn(expr) -> "return " ^ string_of_sexpr expr ^ ";\n";
  | SIf(e, s, SBlock([])) ->
      "if (" ^ string_of_sexpr e ^ ")\n" ^ string_of_sstmt s
  | SIf(e, s1, s2) ->  "if (" ^ string_of_sexpr e ^ ")\n" ^
      string_of_sstmt s1 ^ "else\n" ^ string_of_sstmt s2
  | SFor(e1, e2, e3, s) ->
      "for (" ^ string_of_sexpr e1  ^ " ; " ^ string_of_sexpr e2 ^ " ; " ^
      string_of_sexpr e3  ^ ") " ^ string_of_sstmt s
  | SWhile(e, s) -> "while (" ^ string_of_sexpr e ^ ") " ^ string_of_sstmt s
  | SBreak -> "break;"
  | SEmptyReturn -> "return;"

let string_of_sfdecl fdecl =
  string_of_typ fdecl.styp ^ " " ^
  fdecl.sfname ^ "(" ^ String.concat ", " (List.map snd fdecl.sformals) ^
  ")\n{\n" ^
  String.concat "" (List.map string_of_vdecl fdecl.slocals) ^
  String.concat "" (List.map string_of_sstmt fdecl.sbody) ^
  "}\n"

let string_of_sprogram (vars, funcs) =
  String.concat "" (List.map string_of_vdecl vars) ^ "\n" ^
  String.concat "\n" (List.map string_of_sfdecl funcs)

