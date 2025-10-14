(** Tagless-final algebra, implemented as OCaml abstract types,
    for lightweight code component.
    @see http://loome.cs.illinois.edu/pubs/components-A.pdf *)

module Cde_core = struct
  module type S = sig
    type number
    type dict
    type none
    type 'a expr
    type 'a stmt
    type 'a ref

    val if_ : bool expr -> (unit -> unit stmt) -> unit stmt
    type 'a initialization
    val ref : ?name:string -> 'a expr -> 'a initialization

    val bind     : 'a initialization -> ('a ref -> 'b stmt) -> 'b stmt
    val ( let* ) : 'a initialization -> ('a ref -> 'b stmt) -> 'b stmt

    val deref : 'a ref -> 'a expr
    val ( ! ) : 'a ref -> 'a expr

    val assign : 'a ref -> 'a expr -> unit stmt
    val ( := ) : 'a ref -> 'a expr -> unit stmt

    val cont    : _ stmt -> 'b stmt -> 'b stmt
    val ( >>= ) : _ stmt -> 'b stmt -> 'b stmt
  end
end

module Cde_withliteral = struct
  module type S = sig
    include Cde_core.S

    (** Literal expressions *)

    val number_of_int : int -> number expr
    val number_of_float : float -> number expr
    val bool   : bool -> bool expr
    val string : string -> string expr
    val list : 'a expr list -> 'a list expr
    val not    : bool expr -> bool expr
    val is     : 'a expr -> 'b expr -> bool expr
    val _dict_of_string : string -> dict expr
    module Bool : sig
      val of_number : number expr -> bool expr
    end

    (** Operations on primitive data types *)

    val ( + ) : number expr -> number expr -> number expr
    val ( - ) : number expr -> number expr -> number expr
    val ( * ) : number expr -> number expr -> number expr
    val ( / ) : number expr -> number expr -> number expr
    val ( ^+ ): string expr -> string expr -> string expr
    val ( != ): number expr -> number expr -> bool expr

    (** List comprehension expression *)
    (* val list__ : ('a expr -> 'b expr) stmt -> for_in:'a list expr -> 'b list expr *)

    (* [%lst for x in arr; do x + 1 done ] *)
    val if__ : bool expr -> then_:'a expr -> else_:('a expr) -> 'a expr

    (* val f_ : ('a, unit, string expr) format -> 'a *)
    val none : none expr
  end
end

module Cde_withext = struct
  module type S = sig
    include Cde_withliteral.S

    type 'a awaitable
    val await : 'a expr awaitable -> 'a expr

    val ignore_ : 'a expr -> 'a stmt
  end
end

class virtual kwargs = object
  method virtual all_ : (string * unit) list
end

type 'a t_kwargs = 'a constraint 'a = < kwargs ; .. > as 'a

module Cde_withstd = struct
  module type S = sig
    include Cde_withext.S
    val print : string expr -> unit stmt
    (* val print_int : int expr -> unit stmt *)

    type libs
    type 'a scoped

    module type LibEnv = sig
      val libs : libs
    end

    type spec

    module type Importable = sig
      val spec : spec
    end

    val import : ?alias:string -> (module Importable) -> (module LibEnv) scoped
    val ( let+ ) : (module LibEnv) scoped -> ((module LibEnv) -> 'b stmt) -> 'b stmt

    module Os : sig
      include Importable
      module M (_ : LibEnv) : sig
        val getenv : string expr -> string expr
        val getcwd : unit -> string expr
      end
    end

    type unknown

    module Ast : sig
      include Importable
      module M (_ : LibEnv) : sig
        val literal_eval : string expr -> unknown expr
      end
    end

    module Json : sig
      include Importable
      module M (_ : LibEnv) : sig
        val dumps : dict expr -> string expr
        val loads : string expr -> dict expr
      end
    end

    module Asyncio : sig
      include Importable
      module M (_ : LibEnv) : sig
        type proc
        module Subprocess : sig
          type pipe
          val pipe : pipe (* default pipe mode *)
          val communicate : proc expr -> unit -> (string * string) expr awaitable
          val returncode  : proc expr -> number expr
        end
        val create_subprocess_shell : string expr -> ?stdout:Subprocess.pipe -> ?stderr:Subprocess.pipe -> unit -> proc expr awaitable
      end
    end

    val return : 'a expr -> 'a stmt
    val def0 : ?name:string -> unit -> kwargs:('kwargs t_kwargs) -> (unit -> kwargs:('kwargs t_kwargs) -> 'ret stmt) -> (unit -> 'ret) initialization
    val async_def0 : ?name:string -> unit -> (unit -> 'ret stmt) -> (unit -> 'ret awaitable) initialization 
    val def1 : ?name:string -> unit -> ?name_1:string -> kwargs:('kwargs t_kwargs) -> ('a ref -> kwargs:('kwargs t_kwargs) -> 'ret stmt) -> ('a -> 'ret) initialization
    val async_def1 : ?name:string -> unit -> ?name_1:string -> kwargs:('kwargs t_kwargs) -> ('a ref -> kwargs:('kwargs t_kwargs) -> 'ret stmt) -> ('a -> 'ret awaitable) initialization
    val def2 : ?name:string -> unit -> ?name_1:string -> ?name_2:string -> kwargs:('kwargs t_kwargs) -> ('a ref -> 'b ref -> kwargs:('kwargs t_kwargs) -> 'ret stmt) -> ('a -> 'b -> 'ret) initialization
    val async_def2 : ?name:string -> unit -> ?name_1:string -> ?name_2:string -> kwargs:('kwargs t_kwargs) -> ('a ref -> 'b ref -> kwargs:('kwargs t_kwargs) -> 'ret stmt) -> ('a -> 'b -> 'ret awaitable) initialization
    val unit : unit expr

    type ('a, 'b) destructed2_ref
    val ref2 : ?names:(string * string) -> ('a * 'b) expr -> ('a, 'b) destructed2_ref
    val ( let** ) : ('a, 'b) destructed2_ref -> (('a ref * 'b ref) -> 'c stmt) -> 'c stmt

    val raise_ : 'a expr -> unit stmt

    type 'a exn_
    val exception_ : string expr -> string exn_ expr

    val mkfunc0 : (unit -> 'ret) ref -> (unit -> 'ret expr)
    val mkasyncfunc0 : (unit -> 'ret awaitable) ref -> (unit -> 'ret expr awaitable)
    val mkfunc1 : ('a -> 'ret) ref -> ('a expr -> 'ret expr)
    val mkasyncfunc1 : ('a -> 'ret awaitable) ref -> ('a expr -> 'ret expr awaitable)
    val mkfunc2 : ('a -> 'b -> 'ret) ref -> ('a expr -> 'b expr -> 'ret expr)

    type 'a klass
    val klass__dict : dict klass
    val klass__string : string klass
    type 'a assertion
    val assert__isinstance : unknown ref -> 'b klass -> 'b assertion 
    val ( let- ) : 'a assertion -> ('a ref -> 'b stmt) -> 'b stmt

    module Dict : sig
      val ( !. ) : dict expr -> string expr -> unknown expr
      val of_assoc__single_t : (string expr * 'a expr) list -> dict expr
      (* module type ITEM : sig type t val v : t end *)
      (* val of_assoc : (string expr * (module ITEM) expr) list -> (module ITEM) expr *)
    end

    val def_varargs :
      ?name:string -> ?name_args:string -> ?name_kwargs:string ->
      (unknown list ref -> dict ref -> 'ret stmt) ->
      (unknown list -> dict -> 'ret) initialization

    type 'a spreaded

    module Spreading : sig
      val ( * ) : 'a list expr -> 'a list spreaded expr
      val ( ** ) : dict expr -> dict spreaded expr
    end

    val mkfunc_varargs : (unknown list -> dict -> 'ret) ref -> (unknown list spreaded expr -> dict spreaded expr -> 'ret expr)

    module Function : sig
      type 'a t
      val v2 : ('a -> 'b -> 'ret) expr -> 'c t expr
      val r__name__ : _ t expr -> string expr
      val r__module__ : _ t expr -> string expr
    end
    (* val ( #/ ) : string -> unit stmt *)
  end
end
