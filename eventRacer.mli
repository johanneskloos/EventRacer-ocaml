type command =
    Enter_scope of string option
  | Exit_scope
  | Read_memory of string option
  | Write_memory of string option
  | Post of int
  | Value of string option
type event_action_type =
    Unknown
  | Timer
  | UserInterface
  | Network
  | Continuation
type arc = { tail : int; head : int; duration : int; }
type event_action = { evtype : event_action_type; commands : command array; }
type event_log = { events : event_action array; arcs : arc array; }

val read_event_log : string -> event_log
