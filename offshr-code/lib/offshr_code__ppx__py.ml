open Ppxlib

let rule__py_mod =
  Context_free.Rule.extension @@
  Extension.V3.declare "py__mod"
  Extension.Context.expression
  Ast_pattern.(single_expr_payload (pexp_let __ __ __)) @@
  fun ~ctxt _rec_ bindings body ->
  let loc = Expansion_context.Extension.extension_point_loc ctxt in
  let (module A) = Ast_builder.make loc in
  match bindings with
  | [{ pvb_pat = { ppat_desc = Ppat_unpack { txt = outmodname; _ }; _ }; pvb_expr = { pexp_desc = Pexp_apply (import, [Nolabel, { pexp_desc = Pexp_pack { pmod_desc = Pmod_ident { txt = Lident modname ; _ }; _ }; _ }]) ; _ }; _ }] ->
    A.pexp_letop @@ A.letop
      ~let_:{ pbop_loc = !Ast_helper.default_loc; pbop_op = { txt = "let+"; loc = !Ast_helper.default_loc}; pbop_pat = A.ppat_var(
        { txt = "os"; loc = !Ast_helper.default_loc }
      ); pbop_exp = (
        A.pexp_apply
          import
          [Nolabel, (A.pexp_pack (A.pmod_ident { txt = Lident modname; loc = !Ast_helper.default_loc }))]
      ) }
      ~ands:[]
      ~body:(
        A.pexp_letmodule
          { txt = outmodname; loc = !Ast_helper.default_loc }
          ( A.pmod_apply (A.pmod_ident { txt = Ldot (Lident modname, "M"); loc = !Ast_helper.default_loc }) (A.pmod_unpack (A.pexp_ident { txt = Lident "os"; loc = !Ast_helper.default_loc})))
          body
      )
  | _ -> failwith "??"

let () =
  Driver.register_transformation
    ~rules:[ rule__py_mod ] "offshr-code+py"
