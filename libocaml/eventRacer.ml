type reference =
  | Nothing
  | String of int * string
  | Number of int

type command =
  | Enter_scope of reference
  | Exit_scope
  | Read_memory of reference
  | Write_memory of reference
  | Post of int
  | Value of reference

type event_action_type =
  | Unkown
  | Timer
  | UserInterface
  | Network
  | Continuation

type arc = {
  tail: int;
  head: int;
  duration: int
}

type event_action = {
  evtype: event_action_type;
  commands: command array
}

type event_log = {
  events: event_action array;
  arcs: arc array;
}

exception OpenException
exception ReadException
exception ParseException

let _ = Callback.register_exception "open_exception" OpenException
let _ = Callback.register_exception "read_exception" ReadException
let _ = Callback.register_exception "parse_exception" ParseException

external read_event_log: string -> event_log = "read_event_log"
