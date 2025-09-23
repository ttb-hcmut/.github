open Microcluster_exec
open Clientside

type ('a, 'b) callback = [ `Promise of string * 'a ] -> 'b program
    
type 'imp intercept = ([ `Object ], ('imp, [ `Unknown ]) abstract_value) callback

let upine (m: _ intercept) =
  m (`Promise ("task", `Object))

let test_generic () =
  let session_name = "a81-yuu-znm" in
  let intercept = Syntax.(fun task ->
    let open Clientside_common in
    let* task      = Task.to_dict task
    and* task_name =
      Attr_get.str "name" task in
    Fs_socket.fetch !session_name ~name:task_name task
    >>= Dict_get.str "return_value"
    >>= Ast.literal_eval
  ) in
  intercept
  |> upine
  |> Clientside_jsont.encode_string
  |> Alcotest.(check string) "lol" {|[{"rhs_type":"normal","lhs":"a","rhs":"task.to_dict()"},{"rhs_type":"normal","lhs":"b","rhs":"task.name"},{"rhs_type":"await","lhs":"c","rhs":"fs_socket.comm(\"a81-yuu-znm\", a, name=b)"},{"rhs_type":"normal","lhs":"ca","rhs":"c[\"return_value\"]"},{"rhs_type":"normal","lhs":"cb","rhs":"ast.literal_eval(ca)"}]|}

open Alcotest

let () =
  run "Clientside" [
    "clientside.syntax", [
      test_case "Sample" `Quick test_generic
    ]
  ]
