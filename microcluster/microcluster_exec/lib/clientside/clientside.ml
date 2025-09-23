type ('a, 'future_a) abstract_value =
  [ `Literal of 'a
  | `Promise of string * 'future_a
  ]

type 'a program =
  { body   : PyreAst.Concrete.Statement.t list * 'a
  ; target : [ `Python | `Generic ]
  }

let bind acc f : 'b program =
  let { body = accstmts, retval; target = acctarget } = acc in
  f retval
  |> fun newprog ->
    let { body = newstmts, newretval; target = newtarget } = newprog in
    if acctarget != newtarget
    then failwith "incompatible syntax tree target";
    { acc with body = (newstmts @ accstmts, newretval) }

let join a b =
  let { body = (body1, ret1); _ } = a
  and { body = (body2, ret2); _ } = b in
  { body = (body2 @ body1, (ret1, ret2)) ; target = `Python }

type 'retval statement = PyreAst.Concrete.Statement.t * 'retval

let return (stmt: _ statement) =
  let stmt, retval = stmt in
  { body = ([stmt], retval); target = `Python }

module Syntax = struct
  let ( >>= ) = bind
  and ( let* ) = bind
  and ( and* ) = join
  and ( ! ) x = `Literal x
end

(** a null location, because location info is redundant in this use case. *)
let location =
  let open PyreAst.Concrete in
  let zero = Position.make_t ~line:0 ~column:0 () in
  Location.make_t ~start:zero ~stop:zero ()

let parse_argument_string =
  let open PyreAst.Concrete in
  function
  | `Promise (id, `String) ->
    ( Expression.make_name_of_t
        ~location
        ~id:(Identifier.make_t id ())
        ~ctx:(ExpressionContext.make_load_of_t ())
        () )
  | `Literal x ->
    ( Expression.make_constant_of_t
        ~location
        ~value:(Constant.make_string_of_t x)
        () )
    
let parse_argument_object =
  let open PyreAst.Concrete in
  function
  | `Promise (id, `Object) ->
    ( Expression.make_name_of_t
        ~location
        ~id:(Identifier.make_t id ())
        ~ctx:(ExpressionContext.make_load_of_t ())
        () )
  | `Literal _ ->
    failwith "literal object is not supported"

let parse_argument_dict =
  let open PyreAst.Concrete in
  function
  | `Promise (id, `Dict) ->
    ( Expression.make_name_of_t
        ~location
        ~id:(Identifier.make_t id ())
        ~ctx:(ExpressionContext.make_load_of_t ())
        () )
  | `Literal _ ->
    failwith "literal dict is not supported"

let parse_argument_unknown =
  let open PyreAst.Concrete in
  function
  | `Promise (id, `Unknown) ->
    ( Expression.make_name_of_t
        ~location
        ~id:(Identifier.make_t id ())
        ~ctx:(ExpressionContext.make_load_of_t ())
        () )
  | `Literal _ ->
    failwith "literal unknown is not supported"

let attr_get__str attr receiver =
  let open PyreAst.Concrete in
  let receiver = parse_argument_object receiver in
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
      ( Expression.make_attribute_of_t
          ~location
          ~value:receiver
          ~attr:(Identifier.make_t attr ())
          ~ctx:(ExpressionContext.make_load_of_t ())
          () )
     () in
  return (stmt, `Promise (varname, `String))

let attr_get__unknown attr receiver =
  let open PyreAst.Concrete in
  let receiver = parse_argument_object receiver in
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
      ( Expression.make_attribute_of_t
          ~location
          ~value:receiver
          ~attr:(Identifier.make_t attr ())
          ~ctx:(ExpressionContext.make_load_of_t ())
          () )
     () in
  return (stmt, `Promise (varname, `Unknown))

module Attr_get = struct
  let str = attr_get__str
  let unknown = attr_get__unknown
end

let dict__init () =
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
            ~id:(Identifier.make_t "dict" ())
            ~ctx:(ExpressionContext.make_load_of_t ())
            () )
        () )
     () in
  return (stmt, `Promise (varname, `Dict))

module Dict = struct
  let init = dict__init
end

let dict_get__str attr receiver =
  let open PyreAst.Concrete in
  let receiver = parse_argument_dict receiver in
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
      ( Expression.make_subscript_of_t
          ~location
          ~value:receiver
          ~slice:
          ( Expression.make_constant_of_t
              ~location
              ~value:
              ( Constant.make_string_of_t attr )
              () )
          ~ctx:(ExpressionContext.make_load_of_t ())
          () )
     () in
  return (stmt, `Promise (varname, `String))

module Dict_get = struct
  let str = dict_get__str
end

let dict_set__str attr value receiver =
  let open PyreAst.Concrete in
  let value    = parse_argument_string value
  and arg_receiver = parse_argument_dict receiver in
  let stmt =
    Statement.make_assign_of_t
      ~location
      ~targets:[
      ( Expression.make_name_of_t
          ~location
          ~id:(Identifier.make_t "_" ())
          ~ctx:(ExpressionContext.make_store_of_t ())
          () ) ]
      ~value:
      ( Expression.make_call_of_t
        ~location
        ~func:
        ( Expression.make_attribute_of_t
          ~location
          ~value:arg_receiver
          ~attr:(Identifier.make_t "update" ())
          ~ctx:(ExpressionContext.make_load_of_t ())
          () )
        ~keywords:
        [
        ( Keyword.make_t
            ~location
            ~arg:(Identifier.make_t attr ())
            ~value
            ()
        )
        ]
        () )
     () in
  return (stmt, receiver)

module Dict_set = struct
  let str = dict_set__str
end

module Name = Name
