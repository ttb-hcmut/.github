open Clientside

let fs_socket__comm :
  (string, [ `String ]) abstract_value ->
  (string, [ `String ]) abstract_value ->
  (_, [ `Dict ]) abstract_value ->
  [ `Promise of string * [ `Dict ] ] program =
  fun target data info ->
  let open PyreAst.Concrete in
  let arg_target = parse_argument_string target
  and arg_data   = parse_argument_string data
  and info       = parse_argument_dict info
  and varname    =
    Name.make () in
  let stmt =
    Statement.make_assign_of_t
      ~location
      ~targets:[
      ( Expression.make_name_of_t
          ~location
          ~id:(Identifier.make_t varname ())
          ~ctx:(ExpressionContext.make_store_of_t ())
          () ) ]
      ~value:
      ( Expression.make_await_of_t
          ~location
          ~value:
          ( Expression.make_call_of_t
              ~location
              ~func:
              ( Expression.make_name_of_t
                  ~location
                  ~id:(Identifier.make_t "fs_socket.comm" ())
                  ~ctx:(ExpressionContext.make_load_of_t ())
                  () )
              ~args:[arg_target; arg_data; info]
              ~keywords:[]
              () )
          ()
      )
     () in
  return (stmt, `Promise (varname, `Dict))

let ast__literal_eval x =
  let x = parse_argument_string x in
  let open PyreAst.Concrete in
  let varname = Name.make () in
  let stmt =
    Statement.make_assign_of_t
      ~location
      ~targets:[
      ( Expression.make_name_of_t
          ~location
          ~id:(Identifier.make_t varname ())
          ~ctx:(ExpressionContext.make_store_of_t ())
          () ) ]
      ~value:
      ( Expression.make_call_of_t
          ~location
          ~func:
          ( Expression.make_name_of_t
              ~location
              ~id:(Identifier.make_t "ast.literal_eval" ())
              ~ctx:(ExpressionContext.make_load_of_t ())
              () )
          ~args:[x]
          ~keywords:[]
          () )
     () in
  return (stmt, `Promise (varname, `Unknown))

let task__to_dict task =
  let task = parse_argument_object task in
  let open PyreAst.Concrete in
  let varname = Name.make () in
  let stmt =
    Statement.make_assign_of_t
      ~location
      ~targets:[
      ( Expression.make_name_of_t
          ~location
          ~id:(Identifier.make_t varname ())
          ~ctx:(ExpressionContext.make_store_of_t ())
          () ) ]
      ~value:
      ( Expression.make_call_of_t
          ~location
          ~func:
          ( Expression.make_attribute_of_t
              ~location
              ~value:task
              ~attr:(Identifier.make_t "to_dict" ())
              ~ctx:(ExpressionContext.make_load_of_t ())
              () )
          ~args:[]
          ~keywords:[]
          () )
     () in
  return (stmt, `Promise (varname, `Dict))

let os__get_cwd () =
  let open PyreAst.Concrete in
  let varname = Name.make () in
  let stmt =
    Statement.make_assign_of_t
      ~location
      ~targets:[
      ( Expression.make_name_of_t
          ~location
          ~id:(Identifier.make_t varname ())
          ~ctx:(ExpressionContext.make_store_of_t ())
          () ) ]
      ~value:
      ( Expression.make_call_of_t
          ~location
          ~func:
          ( Expression.make_attribute_of_t
              ~location
              ~value:
              ( Expression.make_name_of_t
                  ~location
                  ~id:(Identifier.make_t "os" ())
                  ~ctx:(ExpressionContext.make_load_of_t ())
                  () )
              ~attr:(Identifier.make_t "getcwd" ())
              ~ctx:(ExpressionContext.make_load_of_t ())
              () )
          ~args:[]
          ~keywords:[]
          () )
     () in
  return (stmt, `Promise (varname, `String))

module Ast = struct
  let literal_eval = ast__literal_eval
end

module Fs_socket = struct
  let fetch = fs_socket__comm
end

module Os = struct
  let getcwd = os__get_cwd
end

module Task = struct
  let to_dict = task__to_dict
end
