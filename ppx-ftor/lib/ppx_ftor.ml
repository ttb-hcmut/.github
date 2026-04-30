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
  fun { ppat_desc = p ; _ } body ->
    match p with
    | Ppat_constraint ({ ppat_desc = Ppat_unpack ftor_param_name ; _ }, { ptyp_desc = Ptyp_package ftor_param_sig ; _ }) ->
      A.pexp_pack (
        A.pmod_functor (Named (ftor_param_name, Package_type.to_module_type ~loc ftor_param_sig)) (A.pmod_structure [
          A.pstr_value Nonrecursive [A.value_binding ~pat:(A.ppat_var { txt = "v" ; loc }) ~expr:body]
        ])
      )
    | _ -> failwith "wtf"

let () =
  let ftor_imm ?(name = "ftor") () =
    Extension.V3.declare
      name
      Extension.Context.expression
      Ast_pattern.(single_expr_payload (pexp_fun __ __ __ __))
      (fun ~ctxt _lbl _exp0 -> expand__ftor_imm ~ctxt)
    |> Context_free.Rule.extension
  and ftor_imm' ?(name = "ftor'") () =
    Extension.V3.declare
      name
      Extension.Context.expression
      Ast_pattern.(single_expr_payload (pexp_function __))
      (fun ~ctxt -> function [{ pc_lhs ; pc_guard = _ ; pc_rhs }] -> expand__ftor_imm ~ctxt pc_lhs pc_rhs | _ -> failwith "sdf3wer")
    |> Context_free.Rule.extension
  in
  Driver.register_transformation
    ~rules:[ ftor_imm (); ftor_imm ~name:"functor" (); ftor_imm' (); ftor_imm' ~name:"functor'" () ] "ppx-ftor"
