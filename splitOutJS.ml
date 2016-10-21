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
  | Post (id, Some (src, Some duration, tgt)) ->
      pf pp "@[<hov 2>Triggering %d@ (edge: %d -%d-> %d)@]"
        id src duration tgt
  | Post (id, Some (src, None, tgt)) ->
      pf pp "@[<hov 2>Triggering %d@ (edge: %d -> %d)@]"
        id src tgt
  | Post (id, None) ->
      pf pp "@[<hov 2>Triggering %d@]" id
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

let js_entry =
  Pcre.regexp ~study:true "^(json|JS|declare_jsfunction|declare_globalvar)"

let rec split_commands_impl level c1 c2 evs = match level, evs with
  | None, ((Enter (String (_, scope))) as ev :: evs)
            when Pcre.pmatch ~rex:js_entry scope ->
      split_commands_impl (Some 0) (ev::c1) (ev::c2) evs
  | Some i, ((Enter _) as ev) :: evs ->
      split_commands_impl (Some (i+1)) (ev::c1) c2 evs
  | Some 0, Exit :: evs ->
      split_commands_impl None (Exit ::c1) (Exit ::c2) evs
  | Some i, Exit :: evs ->
      split_commands_impl (Some (i-1)) (Exit ::c1) c2 evs
  | Some _, ev :: evs ->
      split_commands_impl level (ev::c1) c2 evs
  | None, ev :: evs ->
      split_commands_impl level c1 (ev::c2) evs
  | _, [] ->
      (BatList.rev c1,
       BatList.rev c2)

let split_commands = split_commands_impl None [] []

let empty { commands } = commands <> []

let split_trace { events; deps } =
  let (events1, events2) =
    BatList.split (BatList.map (fun { evtype; id; commands }->
                                  let (c1, c2) = split_commands commands
                                  in ({ evtype; id; commands = c1 },
                                      { evtype; id; commands = c2 }))
                     events)
  in ({ events = BatList.filter empty events1; deps },
      { events = BatList.filter empty events2; deps })

let () =
  Arg.parse [] (fun filename ->
                  let (js_trace, html_trace) =
                    split_trace (load_and_filter filename)
                  in
                  Format.printf "@[<v>Traces for %s:@ JS:@ %a@ @ HTML:@ %a@ @]"
                    filename
                    pp_trace js_trace
                    pp_trace html_trace)
    "printCleanLog files"
