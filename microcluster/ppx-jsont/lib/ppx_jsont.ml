open Ppxlib
open Ast_builder.Default

let sig_type_decl ~ctxt:_ (_, type_decls) =
  type_decls |> List.map begin function
    | { ptype_name; ptype_loc = loc ; _ } ->
      psig_value ~loc
        { pval_name = { txt = "jsont"; loc }
        ; pval_type =
          ptyp_constr ~loc
            { txt = Longident.(Ldot (Lident "Jsont", "t")); loc }
            [ ptyp_constr ~loc
              { txt = lident ptype_name.txt; loc }
              [] ]
        ; pval_attributes = []
        ; pval_loc  = loc
        ; pval_prim = []
        }
  end

let sig_type_decl =
  Deriving.Generator.V2.make_noarg sig_type_decl

let _ =
  Deriving.add "json"
    ~sig_type_decl
