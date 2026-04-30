module Option = struct
  include Option
  let value ~default = function
  | Some x -> x
  | None -> default ()
end

module Name = struct
  type id_state =
    { mutable last : string
    }

  let global = { last = "a" }

  let increment id_state =
    let init = String.sub id_state.last 0 (String.length id_state.last - 1) in
    let newstr =
    match (String.get id_state.last (String.length id_state.last - 1)) with
    | 'a' -> init ^ "b"
    | 'b' -> init ^ "c"
    | 'c' -> init ^ "d"
    | 'd' -> init ^ "e"
    | 'e' -> init ^ "f"
    | 'f' -> init ^ "g"
    | 'g' -> init ^ "h"
    | 'h' -> init ^ "i"
    | 'i' -> init ^ "j"
    | 'j' -> init ^ "k"
    | 'k' -> init ^ "l"
    | 'l' -> init ^ "m"
    | 'm' -> init ^ "n"
    | 'n' -> init ^ "o"
    | 'o' -> init ^ "p"
    | 'p' -> init ^ "q"
    | 'q' -> init ^ "r"
    | 'r' -> init ^ "s"
    | 's' -> init ^ "t"
    | 't' -> init ^ "u"
    | 'u' -> init ^ "v"
    | 'v' -> init ^ "w"
    | 'w' -> init ^ "x"
    | 'x' -> init ^ "y"
    | 'y' -> init ^ "z"
    | 'z' -> id_state.last ^ "a"
    | _   -> failwith "wt"
    in
    { last = newstr }

  let make () =
    let value = global.last
    and new_id_state = increment global in
    global.last <- new_id_state.last;
    value
end

let with_increased_indent indent f =
  let previndent = !indent in
  indent := !indent + 1;
  let v = f () in
  indent := previndent; v

let expand_indent state__indent =
  String.init (!state__indent * 2) (fun _ -> ' ')

module type State = sig val state__indent : int ref end

module KK = struct
  type _ kexpr = string
  type kdict = string
  type _ kinitialization = { line: string; refname: string }
  type _ kref = { name: string }
  let kref ?name expr =
    let refname = Option.value name ~default:Name.make in
    let line = refname ^ " = " ^ expr in
    { refname; line }
end

module Python (State : State) = struct
  type number = string
  type dict = KK.kdict
  type none
  type 'a expr = 'a KK.kexpr
  type _ stmt = string
  type 'a ref = 'a KK.kref

  let if_ b_expr f =
    with_increased_indent State.state__indent @@ fun () ->
    let content = "if " ^ b_expr ^ ":\n" ^ expand_indent State.state__indent ^ f () in
    content

  type 'a initialization = 'a KK.kinitialization
  let ref = KK.kref

  let bind line f =
    (* FIXME(kinten) can we use buffer? can we track text length? *)
    (let open KK in line.line) ^ "\n" ^ expand_indent State.state__indent ^ f KK.{ name = line.refname }

  let ( let* ) = bind

  let deref x = let open KK in x.name
  let ( ! ) = deref 

  let assign ref rhs = (let open KK in ref.name) ^ " = " ^ rhs
  let ( := ) = assign

  let cont a b =
    a ^ "\n" ^ expand_indent State.state__indent ^ b

  let ( >>= ) = cont
end

module PythonLiteral = struct
  let number_of_int = Stdlib.string_of_int
  let number_of_float = Stdlib.string_of_float
  let bool = function true -> "True" | false -> "False"
  let string x = "\"" ^ x ^ "\""
  let list xs = "[" ^ (xs |> String.concat ", ") ^ "]"
  let not x = "not (" ^ x ^ ")"
  let is a b = a ^ " is " ^ b
  let _dict_of_string x = "ast.literal_eval(" ^ x ^ ")"
  module Bool = struct
    let of_number x = "bool(" ^ x ^ ")"
  end

  let ( + ) x y = x ^ " + " ^ y
  let ( - ) x y = x ^ " - " ^ y
  let ( * ) x y = x ^ " * " ^ y
  let ( / ) x y = x ^ " / " ^ y
  let ( ^+ ) x y = "(" ^ x ^ ") + (" ^ y ^ ")"
  let ( != ) x y = x ^ " != " ^ y

  (* let list__ f ~for_in xs =  *)
  let if__ cond ~then_ ~else_ = then_ ^ " if " ^ cond ^ " else " ^ else_
  let none = "None"
end

module PythonExt = struct
  type _ awaitable = string
  let await expr = "await (" ^ expr ^ ")"

  let ignore_ x = x
end

class virtual lib = object
  method virtual name : string
end

type kspec = { namespace: string }

module PythonStd (State : State) = struct
  let print s = "print(" ^ s ^ ")"

  type libs = { content: string; namespace: string } 
  type 'a scoped = 'a

  module type LibEnv = sig
    val libs : libs
  end

  type spec = kspec
  
  module type Importable = sig
    val spec : spec
  end

  let import ?alias (module I : Importable) : (module LibEnv) = let namespace = Option.value alias ~default:Name.make in let namespace' = namespace |> (function x when x = I.spec.namespace || (match String.split_on_char '.' I.spec.namespace with [] -> failwith "??" | [_] -> false | xs -> List.nth xs (List.length xs - 1) = namespace) -> None | x -> Some x) in (module (struct let libs = { content = (("import " ^ I.spec.namespace) |> fun x -> match namespace' with None -> x | Some aliased_ns -> x ^ " as " ^ aliased_ns); namespace } end))
  let ( let+ ) (module Rhs : LibEnv) f = Rhs.libs.content ^ "\n" ^ expand_indent State.state__indent ^ f (module Rhs : LibEnv)

  module Os = struct
    let spec = { namespace = "os" }
    module M (I : LibEnv) = struct
      let getenv s = I.libs.namespace ^ ".getenv(" ^ s ^ ")"
      let getcwd () = I.libs.namespace ^ ".getcwd()"
    end
  end

  type unknown = string

  module Ast = struct
    let spec = { namespace = "ast" }
    module M (I : LibEnv) = struct
      let literal_eval s = I.libs.namespace ^ ".literal_eval(" ^ s ^ ")"
    end
  end

  module Json = struct
    let spec = { namespace = "json" }
    module M (I : LibEnv) = struct
      let dumps v = I.libs.namespace ^ ".dumps(" ^ v ^ ")"
      let loads str = I.libs.namespace ^ ".loads(" ^ str ^ ")"
    end
  end

  module Asyncio = struct
    let spec = { namespace = "asyncio" }
    module M (I : LibEnv) = struct
      type proc = string
      module Subprocess = struct
        type pipe = string
        let  pipe = I.libs.namespace ^ ".subprocess.PIPE"
        let  communicate self () = self ^ ".communicate()"
        let  returncode  self    = self ^ ".returncode"
      end
      let create_subprocess_shell cmd ?stdout ?stderr () = I.libs.namespace ^ ".create_subprocess_shell(" ^ (([cmd] @ (match stdout with None -> [] | Some stdout -> ["stdout=" ^ stdout]) @  (match stderr with None -> [] | Some stderr -> ["stderr=" ^ stderr])) |> String.concat ", ") ^ ")"
    end
  end

  type 'a type_ = unit -> 'a KK.kexpr
  let number_t () = "0"
  let string_t () = "\"\""
  let bool_t () = "True"
  let dict_t () = "{}"
  let return  = fun expr -> "return (" ^ expr ^ ")"
  let def0 ?name () =
    let funname = Option.value name ~default:Name.make in
    fun ~kwargs ->
    fun f ->
    let kwargs' = (kwargs :> (< all_: (string * unit) list >))#all_ |> List.map (fun (name, ()) -> name ^ "=None") in
    with_increased_indent State.state__indent @@ fun () ->
    let line = "def " ^ funname ^ "(" ^ (((match kwargs' with [] -> [] | xs -> "*__args" :: xs)) |> String.concat ", ") ^ "):\n" ^ expand_indent State.state__indent ^ f () ~kwargs:kwargs ^ "\n" in
    KK.{ line; refname = funname }
  let async_def0 ?name () f = def0 ?name () ~kwargs:object method all_ = [] end (fun () ~kwargs:_ -> f ()) |> fun x -> KK.{ x with line = "async " ^ x.line }
  let def1 ?name () =
    let funname = Option.value name ~default:Name.make in
    fun ?name_1 ~kwargs ->
      let a = let name = Option.value name_1 ~default:Name.make in KK.{ name } in
    fun f ->
    let kwargs' = (kwargs :> (< all_: (string * unit) list >))#all_ |> List.map (fun (name, ()) -> name ^ "=None") in
    with_increased_indent State.state__indent @@ fun () ->
    let line = "def " ^ funname ^ "(" ^ ((([a] |> List.map (fun x -> let open KK in x.name)) @ (match kwargs' with [] -> [] | xs -> "*__args" :: xs)) |> String.concat ", ") ^ "):\n" ^ expand_indent State.state__indent ^ f a ~kwargs:kwargs ^ "\n" in
    KK.{ line; refname = funname }
  let async_def1 ?name () ?name_1 ~kwargs f = def1 ?name () ?name_1 ~kwargs f |> fun x -> KK.{ x with line = "async " ^ x.line }
  let def2 ?name () =
    let funname = Option.value name ~default:Name.make in
    fun ?name_1 ?name_2 ~kwargs ->
      let a = let name = Option.value name_1 ~default:Name.make in KK.{ name } in
      let b = let name = Option.value name_2 ~default:Name.make in KK.{ name } in
    fun f ->
    let kwargs' = (kwargs :> (< all_: (string * unit) list >))#all_ |> List.map (fun (name, ()) -> name ^ "=None") in
    with_increased_indent State.state__indent @@ fun () ->
    let line = "def " ^ funname ^ "(" ^ ((([a; b] |> List.map (fun x -> let open KK in x.name)) @ (match kwargs' with [] -> [] | xs -> "*__args" :: xs)) |> String.concat ", ") ^ "):\n" ^ expand_indent State.state__indent ^ f a b ~kwargs:kwargs ^ "\n" in
    KK.{ line; refname = funname }
  let async_def2 ?name () ?name_1 ?name_2 ~kwargs f = def2 ?name () ?name_1 ?name_2 ~kwargs f |> fun x -> KK.{ x with line = "async " ^ x.line }
  let unit = ""

  type (_, _) destructed2_ref = { names: string * string; content: string }
  let ref2 ?names expr =
    let name1, name2 = Option.value names ~default:(fun () -> Name.make (), Name.make ()) in
    let content = ([name1; name2] |> String.concat ", ") ^ " = " ^ expr in
    { names = name1, name2; content }
  let ( let** ) { names = name1, name2; content } f =
    content ^ "\n" ^ expand_indent State.state__indent ^ f (KK.{ name = name1 }, KK.{ name = name2 })

  let raise_ x = "raise " ^ x

  type 'a exn_ = string
  let exception_ msg = "Exception(" ^ msg ^ ")"

  let mkfunc0 fdef =
    let KK.{ name = fname } = fdef in
    fun () -> fname ^ "()"

  let mkasyncfunc0 = mkfunc0

  let mkfunc1 fdef =
    let KK.{ name = fname } = fdef in
    fun a -> fname ^ "(" ^ a ^ ")"

  let mkasyncfunc1 = mkfunc1

  let mkfunc2 fdef =
    let KK.{ name = fname } = fdef in
    fun a b -> fname ^ "(" ^ ([a; b] |> String.concat ", ") ^ ")"

  type _ klass = string
  let klass__dict = "dict"
  let klass__string = "str"
  type _ assertion = { content: string; refname: string }
  let assert__isinstance xref klass = { content = "assert isinstance(" ^ xref.KK.name ^ ", " ^ klass ^ ")"; refname = xref.KK.name }
  let ( let- ) line f =
    line.content ^ "\n" ^ expand_indent State.state__indent ^ f KK.{ name = line.refname }

  module Dict = struct
    let ( !. ) dict str = dict ^ "[" ^ str ^ "]"
    let of_assoc__single_t ls = "{ " ^ (ls |> List.map (fun (k, v) -> "(" ^ k ^ "):(" ^ v ^ ")") |> String.concat ", ") ^ " }"
  end

  let def_varargs =
    fun ?name ?name_args ?name_kwargs f ->
    let funname = Option.value name ~default:Name.make in
    let args   = let name = Option.value name_args   ~default:Name.make in KK.{ name } in
    let kwargs = let name = Option.value name_kwargs ~default:Name.make in KK.{ name } in
    with_increased_indent State.state__indent @@ fun () ->
    let line = "def " ^ funname ^ "(*" ^ args.name ^ ", **" ^ kwargs.name ^ "):\n" ^ expand_indent State.state__indent ^ f args kwargs ^ "\n" in
    KK.{ line; refname = funname }

  type _ spreaded = string

  module Spreading = struct
    let ( * ) xs = "*(" ^ xs ^ ")"
    let ( ** ) ks = "**(" ^ ks ^ ")"
  end

  let mkfunc_varargs fdef =
    let KK.{ name = fname } = fdef in
    fun a b -> fname ^ "(" ^ ([a; b] |> String.concat ", ") ^ ")"

  module Function = struct
    type 'a t = 'a
    let v2 f = f
    let r__name__ x = x ^ ".__name__"
    let r__module__ x = x ^ ".__module__"
  end
end
