open Microcluster_exec;;

let main ~device filename =
  let open Eio in
  Eio_main.run @@ fun env ->
  let process_mgr = Stdenv.process_mgr env in
  Mpremote.copy
    ~from:(`local Fpath.(v "one" / "two"))
    ~dest:(`local Fpath.(v "one" / "three"))
    ~process_mgr
  |> ignore

let main =
  let open Cmdliner in
  Cmd.v
  ( Cmd.info "microcluster_exec"
    ~doc:{|A Python / OCaml interpreter that dissects your program and orchestrates distributable tasks to a micro-cluster.|}
  ) @@
  let open Term.Syntax in
  let+ device =
    Arg.
    ( value
    & opt string "/dev/ttyACM0"
    & info ["F"; "file"]
      ~doc:{|Open and use the specific $(docv).|}
      ~docv:"DEVICE"
    )
  and+ filename =
    Arg.
    ( value
    & pos 0 string "main.py"
    & info []
      ~doc:{|Name of the program file to read.|}
      ~docv:"FILENAME"
    ) in
  main ~device filename

let () =
  if !Sys.interactive then () else
  Cmdliner.Cmd.eval main |> exit
