open Fmt
open EventRacer

let pp_reference = Fmt.option ~none:(Fmt.const Fmt.string "(none") Fmt.string

let pp_command pp = function
  | Enter_scope ref ->
      prefix (const string "Entering scope ") pp_reference pp ref
  | Read_memory ref ->
      prefix (const string "Reading from ") pp_reference pp ref
  | Write_memory ref ->
      prefix (const string "Writing to ") pp_reference pp ref
  | Post id ->
      prefix (const string "Posting task ") int pp id
  | Value ref ->
      prefix (const string "Value ") pp_reference pp ref
  | Exit_scope ->
      string pp "Exiting scope"

let str_event_action_type = function
  | Unknown -> "unknown"
  | Timer -> "timer"
  | UserInterface -> "user interface"
  | Network -> "network"
  | Continuation -> "continuation"
let pp_event_action_type = using str_event_action_type string

let pp_arc pp { tail; head; duration } =
  if duration = -1 then
    pf pp "%d -> %d" tail head
  else
    pf pp "%d -%d-> %d" tail duration head

let pp_event_action pp (i, { evtype; commands }) =
  pf pp "@[<v2>Event %d, cause: %a {@ %a@]@ }@ " i
    pp_event_action_type evtype
    (array ~sep:sp pp_command) commands

let pp_event_log pp { events; arcs } =
  pf pp "@[<v>Events:@ %a@ @ @[<v2>Arcs:@ %a@ @]@]"
    (iter_bindings ~sep:sp Array.iteri pp_event_action) events
    (array ~sep:sp pp_arc) arcs

let dump_one filename =
  Format.printf "@[<v>Log file %s:@ %a@ @ @]"
    filename
    pp_event_log (read_event_log filename)

let () =
  Arg.parse [] dump_one "Usage: dumpLog logfiles"
