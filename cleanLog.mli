module DependencyGraph :
  Graph.Sig.P with type V.t = int with type E.t = int * int option * int
type command =
    Read of string option * string option
  | Write of string option * string option
  | Post of int
  | Enter of string option
  | Exit
type event = {
  evtype : EventRacer.event_action_type;
  id : int;
  commands : command list;
}
type trace = { events : event list; deps : DependencyGraph.t; }
val load : string -> trace
