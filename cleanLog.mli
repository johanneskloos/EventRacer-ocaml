module DependencyGraph :
  Graph.Sig.P with type V.t = int with type E.t = int * int option * int
type command =
    Read of EventRacer.reference * EventRacer.reference option
  | Write of EventRacer.reference * EventRacer.reference option
  | Post of int
  | Enter of EventRacer.reference
  | Exit
type event = {
  evtype : EventRacer.event_action_type;
  id : int;
  commands : command list;
}
type trace = { events : event list; deps : DependencyGraph.t; }
val load_and_filter : string -> trace
