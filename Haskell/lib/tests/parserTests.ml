(** Copyright 2023-2024, Danil P *)

(** SPDX-License-Identifier: LGPL-3.0-or-later *)

open HaskellLib
open Ast
open Parser

let ptest parser printer s =
  match Angstrom.parse_string ~consume:All parser s with
  | Ok a -> Format.printf "%a" printer a
  | Error err -> Format.printf "%s\n" err
;;

let%expect_test _ =
  ptest pexpr pp_expr {|1 + 2 - 3 * 4 + (-5) / 6 * 7 - 8 * 9|};
  [%expect
    {|
      (ExprBinOp (Sub,
         (ExprBinOp (Add,
            (ExprBinOp (Sub,
               (ExprBinOp (Add, (ExprLit (LitInt 1)), (ExprLit (LitInt 2)))),
               (ExprBinOp (Mul, (ExprLit (LitInt 3)), (ExprLit (LitInt 4)))))),
            (ExprBinOp (Mul,
               (ExprBinOp (Div, (ExprUnOp (Neg, (ExprLit (LitInt 5)))),
                  (ExprLit (LitInt 6)))),
               (ExprLit (LitInt 7))))
            )),
         (ExprBinOp (Mul, (ExprLit (LitInt 8)), (ExprLit (LitInt 9)))))) |}]
;;

let%expect_test _ =
  ptest pdecl pp_decl {|x = (1, 2)|};
  [%expect
    {|
    (DeclLet
       ((PatVar "x"), (ExprTuple [(ExprLit (LitInt 1)); (ExprLit (LitInt 2))]))) |}]
;;

let%expect_test _ =
  ptest pdecl pp_decl {|fact n = if (n < 2) then 1 else fact (n - 1) * n|};
  [%expect
    {| 
    (DeclLet
       ((PatVar "fact"),
        (ExprFunc
           ((PatVar "n"),
            (ExprIf ((ExprBinOp (Lt, (ExprVar "n"), (ExprLit (LitInt 2)))),
               (ExprLit (LitInt 1)),
               (ExprBinOp (Mul,
                  (ExprApp ((ExprVar "fact"),
                     (ExprBinOp (Sub, (ExprVar "n"), (ExprLit (LitInt 1)))))),
                  (ExprVar "n")))
               )))))) |}]
;;

let%expect_test _ =
  ptest pdecl pp_decl {|x = [1, 2]|};
  [%expect
    {|
    (DeclLet
       ((PatVar "x"),
        (ExprCons ((ExprLit (LitInt 1)),
           (ExprCons ((ExprLit (LitInt 2)), ExprNil)))))) |}]
;;

let%expect_test _ =
  ptest pdecl pp_decl {|(x, y, z, (a, b)) = (1, 2, 3, (4, 5))|};
  [%expect
    {|
    (DeclLet
       ((PatTuple
           [(PatVar "x"); (PatVar "y"); (PatVar "z");
             (PatTuple [(PatVar "a"); (PatVar "b")])]),
        (ExprTuple
           [(ExprLit (LitInt 1)); (ExprLit (LitInt 2)); (ExprLit (LitInt 3));
             (ExprTuple [(ExprLit (LitInt 4)); (ExprLit (LitInt 5))])]))) |}]
;;

let%expect_test _ =
  ptest pexpr pp_expr {|1 : 2 : 3 : [4, 5, 6]|};
  [%expect
    {|
    (ExprCons ((ExprLit (LitInt 1)),
       (ExprCons ((ExprLit (LitInt 2)),
          (ExprCons ((ExprLit (LitInt 3)),
             (ExprCons ((ExprLit (LitInt 4)),
                (ExprCons ((ExprLit (LitInt 5)),
                   (ExprCons ((ExprLit (LitInt 6)), ExprNil))))
                ))
             ))
          ))
       )) |}]
;;

let%expect_test _ =
  ptest plit pp_lit {|"hello "|};
  [%expect {|
    (LitString "hello ") |}]
;;

let%expect_test _ =
  ptest pexpr pp_expr {|\x y z -> x + y + z + 1|};
  [%expect
    {|
    (ExprFunc
       ((PatVar "x"),
        (ExprFunc
           ((PatVar "y"),
            (ExprFunc
               ((PatVar "z"),
                (ExprBinOp (Add,
                   (ExprBinOp (Add,
                      (ExprBinOp (Add, (ExprVar "x"), (ExprVar "y"))),
                      (ExprVar "z"))),
                   (ExprLit (LitInt 1)))))))))) |}]
;;

let%expect_test _ =
  ptest pdecl pp_decl {|fun a b =\x ->\y -> x + y + 1|};
  [%expect
    {|
    (DeclLet
       ((PatVar "fun"),
        (ExprFunc
           ((PatVar "a"),
            (ExprFunc
               ((PatVar "b"),
                (ExprFunc
                   ((PatVar "x"),
                    (ExprFunc
                       ((PatVar "y"),
                        (ExprBinOp (Add,
                           (ExprBinOp (Add, (ExprVar "x"), (ExprVar "y"))),
                           (ExprLit (LitInt 1)))))))))))))) |}]
;;

let%expect_test _ =
  ptest pdecl pp_decl {|f = let x = 3 in let y = 2 in x + y|};
  [%expect
    {|
    (DeclLet
       ((PatVar "f"),
        (ExprLet ([((PatVar "x"), (ExprLit (LitInt 3)))],
           (ExprLet ([((PatVar "y"), (ExprLit (LitInt 2)))],
              (ExprBinOp (Add, (ExprVar "x"), (ExprVar "y")))))
           )))) |}]
;;

let%expect_test _ =
  ptest pdecl pp_decl {|
  f = 
   let x = 3
       y = 5
       z = 7
   in x + y + z |};
  [%expect
    {|
    (DeclLet
       ((PatVar "f"),
        (ExprLet (
           [((PatVar "x"), (ExprLit (LitInt 3)));
             ((PatVar "y"), (ExprLit (LitInt 5)));
             ((PatVar "z"), (ExprLit (LitInt 7)))],
           (ExprBinOp (Add, (ExprBinOp (Add, (ExprVar "x"), (ExprVar "y"))),
              (ExprVar "z")))
           )))) |}]
;;

let%expect_test _ =
  ptest pdecl pp_decl {|real n = if True || False then false else true|};
  [%expect
    {|
    (DeclLet
       ((PatVar "real"),
        (ExprFunc
           ((PatVar "n"),
            (ExprIf (
               (ExprBinOp (Or, (ExprLit (LitBool true)),
                  (ExprLit (LitBool false)))),
               (ExprVar "false"), (ExprVar "true"))))))) |}]
;;

let%expect_test _ =
  ptest pdecl pp_decl {|x = if True then 45 else 70 + 60|};
  [%expect
    {|
    (DeclLet
       ((PatVar "x"),
        (ExprIf ((ExprLit (LitBool true)), (ExprLit (LitInt 45)),
           (ExprBinOp (Add, (ExprLit (LitInt 70)), (ExprLit (LitInt 60)))))))) |}]
;;

let%expect_test _ =
  ptest pdecl pp_decl {|f [] = 2 + 2|};
  [%expect
    {|
    (DeclLet
       ((PatVar "f"),
        (ExprFunc
           (PatNil, (ExprBinOp (Add, (ExprLit (LitInt 2)), (ExprLit (LitInt 2)))))))) |}]
;;

let%expect_test _ =
  ptest ppat pp_pat {|[1,2,x]|};
  [%expect
    {|
    (PatCons ((PatLit (LitInt 1)),
       (PatCons ((PatLit (LitInt 2)), (PatCons ((PatVar "x"), PatNil)))))) |}]
;;

let%expect_test _ =
  ptest ppat pp_pat {|(x:xs:xsw)|};
  [%expect {|
    (PatCons ((PatVar "x"), (PatCons ((PatVar "xs"), (PatVar "xsw"))))) |}]
;;

let%expect_test _ =
  ptest ppat pp_pat {|(x, y)|};
  [%expect {|
    (PatTuple [(PatVar "x"); (PatVar "y")]) |}]
;;

let%expect_test _ =
  ptest pdecl pp_decl {|f (x:y:xs) = xs|};
  [%expect
    {|
    (DeclLet
       ((PatVar "f"),
        (ExprFunc
           ((PatCons ((PatVar "x"), (PatCons ((PatVar "y"), (PatVar "xs"))))),
            (ExprVar "xs"))))) |}]
;;

let%expect_test _ =
  ptest pdecl pp_decl {|f = [1, 2, 3]|};
  [%expect
    {|
    (DeclLet
       ((PatVar "f"),
        (ExprCons ((ExprLit (LitInt 1)),
           (ExprCons ((ExprLit (LitInt 2)),
              (ExprCons ((ExprLit (LitInt 3)), ExprNil))))
           )))) |}]
;;
