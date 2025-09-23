open Clientside

(** Serializes a {!module:Clientside} semantics into statement-based Python code. *)

module Resolution = struct
  let lhs elt = let lhs, _ = elt in lhs
  let rhs elt = let _, rhs = elt in rhs
  let make_elt a b = (a, b)
  let jsont =
    let open Jsont in
    let expr_jsont =
      let serialize_expr s =
        let open Opine.Unparse in
        expr (State.default ()) s
        |> fun s ->
            Buffer.contents s.source in
      Base.string ( Base.map ~enc:serialize_expr () )
      in
    list
    ( Object.map make_elt
      |> Object.mem "lhs" ~enc:lhs expr_jsont
      |> begin
        let rhs_await_cased_jsont =
          Object.Case.map "await" (
            Object.map Fun.id
            |> Object.mem "rhs" ~enc:Fun.id expr_jsont
            |> Object.finish
          )
        and rhs_normal_cased_jsont =
          Object.Case.map "normal" (
            Object.map Fun.id
            |> Object.mem "rhs" ~enc:Fun.id expr_jsont
            |> Object.finish
          ) in
        Object.case_mem "rhs_type"
        ~enc:rhs
        ~enc_case:
        ( function
          | `Await x -> Object.Case.value rhs_await_cased_jsont x
          | `Normal x -> Object.Case.value rhs_normal_cased_jsont x )
        string
        Object.Case.
        [ make rhs_await_cased_jsont
        ; make rhs_normal_cased_jsont
        ]
      end
      |> Object.finish )
end

let encode_string x =
  let { body = body, _; target } = x in
  if target != `Python then failwith "only python is supported";
  let open PyreAst.Concrete in
  body
  |> List.rev
  |> List.map (function
    | Statement.Assign { targets = [lhs]; value = Expression.Await { value; _ }; _ } -> (lhs, `Await value)
    | Statement.Assign { targets = [lhs]; value; _ } -> (lhs, `Normal value)
    | _ -> failwith "shit"
  )
  |> Jsont_bytesrw.encode_string Resolution.jsont
  |> function
    | Ok x -> x
    | Error x -> failwith x
