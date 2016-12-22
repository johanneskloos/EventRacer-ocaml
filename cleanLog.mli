(** {1 EventRacer event logs} *)
(** Event logs capture certain events during the execution of a website.
    The instrumented browsers provided by the event racer project
    create event logs that contain information about reads from and write
    to memory, task creation and task ordering, as well as scoping information.
  *)

(** {2 The happens-before graph.} *)
(** The vertices are labelled with event numbers, while the edges are
    labelled with [Some t] for timed events with a delay of [t], or
    [None] for other events/happens-before conditions. *)
module DependencyGraph :
  Graph.Sig.P with type V.t = int with type E.t = int * int option * int

(** {2 The event structure.} *)
(** Commands that can occur in an event. *)
type command =
    Read of string option * string option
    (** [Read loc data]: Read from location [loc], yielding [data]. *)
  | Write of string option * string option
    (** [Write loc data]: Write [data] to location [loc]. *)
  | Post of int
    (** [Post id]: Post task [id] *)
  | Enter of string option
    (** [Enter scope]: Enter scope [scope] *)
  | Exit
    (** Exit scope *)

(** A single event. *)
type event = {
  evtype : EventRacer.event_action_type;
  (** Type of the event. *)
  id : int;
  (** Number of the event. *)
  commands : command list;
  (** Commands executed by the event. *)
}

(** A trace. *)
type trace = {
  events : event list;
  (** List of events. *)
  deps : DependencyGraph.t;
  (** Happens-before graph. *)
}

(** [load filename]: Load a trace from [filename]. *)
val load : string -> trace
