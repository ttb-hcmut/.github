open Ppxlib
module A = Ast_builder.Default

module Package_type = struct
  let to_module_type ~loc ((ident, constraints) : package_type) =
    let (module A) = Ast_builder.make loc in
    let v desc = { pmty_loc = loc; pmty_attributes = []; pmty_desc = desc } in
    let ptype__v ~name manifest = { ptype_name = { txt = name ; loc }; ptype_loc = loc; ptype_attributes = []; ptype_params = []; ptype_cstrs = []; ptype_kind = Ptype_abstract; ptype_private = Public; ptype_manifest = Some manifest } in
    v @@ Pmty_with ((v @@ Pmty_ident ident), constraints |> List.map @@ fun (ident, b) ->
      let ident' = let { txt = ident; loc = _} = ident in match ident with Ldot _ | Lapply _ -> failwith "???" | Lident x -> x in
      Pwith_type (ident, ptype__v ~name:ident' b))
end

let expand__ftor_imm ~ctxt =
  let loc = Expansion_context.Extension.extension_point_loc ctxt in
  let (module A) = Ast_builder.make loc in
  let rec a { ppat_desc = p ; _ } body ~paramsrest ~xx =
  match p with
  | Ppat_constraint ({ ppat_desc = Ppat_unpack ftor_param_name ; _ }, { ptyp_desc = Ptyp_package ftor_param_sig ; _ }) ->
    A.pmod_functor (Named (ftor_param_name, Package_type.to_module_type ~loc ftor_param_sig)) (
      let { pexp_desc = body_desc; _ } = body in
      match body_desc with
      | Pexp_function ({pparam_loc = _ ; pparam_desc = Pparam_val (Nolabel, None, p) } :: paramsrest, xx, Pfunction_body body) -> a p body ~paramsrest ~xx
      | _ ->
        A.pmod_structure [
          A.pstr_value Nonrecursive [A.value_binding ~pat:(A.ppat_var { txt = "v" ; loc }) ~expr:(A.pexp_function paramsrest xx (Pfunction_body body))]
        ]
    )
  | _ -> failwith "wtf" in a

let () =
  let ftor_imm ?(name = "ftor") () =
    Extension.V3.declare
      name
      Extension.Context.expression
      Ast_pattern.(single_expr_payload (pexp_function __ __ __))
      (fun ~ctxt params xx body ->
        match params, body with
        | { pparam_loc = _ ; pparam_desc = Pparam_val (lbl, exp0, p) } :: paramsrest, Pfunction_body body ->
        ( match lbl, exp0 with
        | Nolabel, None ->
          let loc = Expansion_context.Extension.extension_point_loc ctxt in
          let (module A) = Ast_builder.make loc in
          A.pexp_pack (expand__ftor_imm ~ctxt p body ~paramsrest ~xx)
        | _ -> failwith "shit"
        )
        | _ -> failwith "wodsf"
      )
    |> Context_free.Rule.extension
  and ftor_imm_let ?(name = "ftor_") () =
    Extension.V3.declare
      name
      Extension.Context.structure_item
      Ast_pattern.(pstr __)
      (fun ~ctxt ->
        ( function
        | [{ pstr_desc = Pstr_value (_recflag, bindings); pstr_loc }] ->
          let funname, nameloc, module_expr, attribs, loc =
          ( match bindings with
          | [{ pvb_pat = { ppat_desc; _ }; pvb_expr = { pexp_desc; _ }; pvb_attributes = attribs; pvb_loc = loc; pvb_constraint = None }] ->
            ( match ppat_desc, pexp_desc with
            | Ppat_var { txt = funname; loc = nameloc }, Pexp_function ({ pparam_loc = _; pparam_desc = Pparam_val (_lbl, _exp0, pp) } :: paramsrest, xx, Pfunction_body body) ->
              (funname, nameloc, expand__ftor_imm ~ctxt pp body ~paramsrest ~xx, attribs, loc)
            | _, _ -> failwith "sslol"
            )
          | _ -> failwith "lol"
          ) in
          let funname =
            String.cat
              (Char.escaped @@ Char.uppercase_ascii @@ String.get funname 0)
              (String.sub funname 1 (String.length funname - 1)) in
          { pstr_desc = Pstr_module { pmb_name = { txt = Some funname; loc = nameloc }; pmb_expr = module_expr; pmb_attributes = attribs; pmb_loc = loc }; pstr_loc }
        | _ -> failwith "shit"
        )
      )
    |> Context_free.Rule.extension
  in
  Driver.register_transformation
    ~rules:[ ftor_imm (); ftor_imm ~name:"functor" (); ftor_imm_let (); ftor_imm_let ~name:"functor_" () ] "ppx-ftor"
