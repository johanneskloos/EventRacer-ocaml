open Fmt
open EventRacer
open CleanLog

let pp_reference pp = function
  | Nothing -> string pp "(none)"
  | String (id, name) -> pf pp "%s (%d)" name id
  | Number id -> braces int  pp id

let pp_command pp = function
  | Read (ref, Some value) ->
      pf pp "@[<hov 2>Read@ %a@ yielding@ %a@]"
        pp_reference ref
        pp_reference value
  | Write (ref, Some value) ->
      pf pp "@[<hov 2>Write@ %a@ with@ %a@]"
        pp_reference ref
        pp_reference value
  | Read (ref, None) ->
      pf pp "@[<hov 2>Read@ %a@]"
        pp_reference ref
  | Write (ref, None) ->
      pf pp "@[<hov 2>Write@ %a@]"
        pp_reference ref
  | Post id ->
      pf pp "@[<hov 2>Triggering event %d@]" id
  | Enter scope ->
      pf pp "@[<hov 2>Entering scope@ %a@]"
        pp_reference scope
  | Exit ->
      pf pp "Exiting scope"

let str_event_action_type = function
  | Unkown -> "unknown"
  | Timer -> "timer"
  | UserInterface -> "user interface"
  | Network -> "network"
  | Continuation -> "continuation"
let pp_event_action_type = using str_event_action_type string

let comma = suffix sp (const string ",")

let pp_event deps pp { evtype; id; commands } =
  pf pp "@[<v2>Event %d (before: @[<hov>[%a],@ @]after: @[<hov>[%a]@]), source: %a {@ %a@ }@]"
    id
    (iter ~sep:comma (fun f -> DependencyGraph.iter_pred f deps) int) id
    (iter ~sep:comma (fun f -> DependencyGraph.iter_succ f deps) int) id
    pp_event_action_type evtype
    (list ~sep:cut pp_command) commands

let pp_trace pp { events; deps } =
  list ~sep:cut (pp_event deps) pp events

let () =
  Arg.parse [] (fun filename ->
                  Format.printf "@[<v>Trace %s:@ %a@ @]"
                    filename
                    pp_trace (load_and_filter filename))
    "printCleanLog files"
