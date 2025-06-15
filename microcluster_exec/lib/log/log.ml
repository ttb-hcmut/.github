open Ppxlib

let subs =
  let pattern =
    let open Re in
    seq [ char '{'; group (any |> rep); char '}' ]
    |> compile in
  fun s ->
  let serializer = ref None in
  Re.replace
    ~all:true
    ~f:(fun groups ->
      serializer :=
        Re.Group.get groups 1
        |> Option.some
      ; "%s")
    pattern s
    |> fun newstr ->
    let serializer =
      serializer |> Stdlib.(!)
      |> Option.value ~default:"Stdlib"
      in
    newstr, serializer

class ast_builder (loc:location) = object (_)
  method pexp_apply = Ast_builder.Default.pexp_apply ~loc
  method pexp_fun = Ast_builder.Default.pexp_fun ~loc
  method evar = Ast_builder.Default.evar ~loc
  method ppat_var = Ast_builder.Default.ppat_var ~loc
  method estring = Ast_builder.Default.estring ~loc
end

let expand ~ctxt =
  let loc = Expansion_context.Extension.extension_point_loc ctxt in
  let ast = new ast_builder loc in
  function path ->
  subs path
  |> function path, serializer ->
  ast#pexp_apply
    (ast#evar "Log_domain.with_report")
    [ Labelled "env",
      (ast#evar "env")
    ; Labelled "msg",
      (ast#pexp_fun
        Nolabel None
        (ast#ppat_var { txt = "x"; loc })
        (ast#pexp_apply
          (ast#evar "Printf.sprintf")
          [ Nolabel, (ast#estring path)
          ; Nolabel,
            (ast#pexp_apply
              (ast#evar (serializer ^ ".to_string"))
              [Nolabel, ast#evar "x"])]))]

let () =
  Extension.V3.declare
    "with_report"
    Extension.Context.expression
    Ast_pattern.(single_expr_payload (estring __))
    expand
  |> Ppxlib.Context_free.Rule.extension
  |> fun rule ->
  Driver.register_transformation
    ~rules:[ rule ] "with_report"
