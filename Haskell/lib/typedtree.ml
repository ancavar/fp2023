(** Copyright 2023-2024, Danil P *)

(** SPDX-License-Identifier: LGPL-3.0-or-later *)

type binder = int [@@deriving show { with_path = false }]

module VarSet = struct
  include Stdlib.Set.Make (Int)

  let pp fmt s =
    Format.fprintf fmt "[ ";
    iter (Format.fprintf fmt "%d; ") s;
    Format.fprintf fmt "]"
  ;;
end

type binder_set = VarSet.t [@@deriving show { with_path = false }]

type ty =
  | TyLit of string
  | TyVar of binder
  | TyArrow of ty * ty
  | TyList of ty
  | TyTuple of ty list
[@@deriving show { with_path = false }]

type scheme = S of binder_set * ty [@@deriving show { with_path = false }]

let pp_type fmt ty =
  let open Format in
  let rec helper fmt = function
    | TyVar n -> fprintf fmt "p%d" n
    | TyLit s -> pp_print_string fmt s
    | TyArrow (l, r) ->
      (match l with
       | TyArrow (_, _) -> fprintf fmt "(%a) -> %a" helper l helper r
       | _ -> fprintf fmt "%a -> %a" helper l helper r)
    | TyList t -> fprintf fmt "[%a]" helper t
    | TyTuple ts ->
      fprintf fmt "(";
      fprintf
        fmt
        "%a"
        (pp_print_list
           ~pp_sep:(fun fmt () -> fprintf fmt ", ")
           (fun fmt t -> fprintf fmt "%a" helper t))
        ts;
      fprintf fmt ")"
  in
  helper fmt ty
;;
