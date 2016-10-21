open Fmt
open EventRacer

let pp_reference pp = function
  | Nothing -> string pp "(none)"
  | String (id, name) -> pf pp "%s (%d)" name id
  | Number id -> braces int  pp id

let pp_command pp = function
  | Enter_scope ref ->
      prefix (const string "Entering scope ") pp_reference pp ref
  | Read_memory ref ->
      prefix (const string "Reading from ") pp_reference pp ref
  | Write_memory ref ->
      prefix (const string "Writing to ") pp_reference pp ref
  | Post ref ->
      prefix (const string "Posting task ") pp_reference pp ref
  | Value ref ->
      prefix (const string "Value ") pp_reference pp ref
  | Exit_scope ->
      string pp "Exiting scope"

let str_event_action_type = function
  | Unkown -> "unknown"
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

let pp_event_action pp { evtype; commands } =
  pf pp "@[<v2>Event, cause: %a {@ %a@]@ }@ "
    pp_event_action_type evtype
    (array ~sep:sp pp_command) commands

let pp_event_log pp { events; args } =
  pf pp "@[<v>Events:@ %a@ @ @[<v2>Arcs:@ %a@ @]@]"
    (array ~sep:sp pp_event_action) events
    (array ~sep:sp pp_arc) args

let dump_one filename =
  try
    Format.printf "@[<v>Log file %s:@ %a@ @ @]"
      filename
      pp_event_log (read_event_log filename)
  with
    | OpenException ->
        Format.printf "Cannot open %s" filename
    | ReadException ->
        Format.printf "Cannot read %s" filename
    | ParseException ->
        Format.printf "Cannot parse %s" filename

let () =
  Arg.parse [] dump_one "Usage: dumpLog logfiles"
