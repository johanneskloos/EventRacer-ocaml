(** {1 Access to raw EventRacer log files} *)
(** This module allows access to the raw contents of EventRacer log files,
    decoded only to the point where the enumerations have been resolved,
    strings instantiated and basic data structures turned to their OCaml
    equivalent.
    
    It is recommended to use the functionality in [CleanLog] instead.
    *)

(** Command types, used in event actions. *)
type command =
    Enter_scope of string option (* Entering a scope; argument: scope name *)
  | Exit_scope (* Exiting a scope *)
  | Read_memory of string option (* Read a value; argument: reference *)
  | Write_memory of string option (* Write a value; argument: reference *)
  | Post of int (* Post a task; argument: task identifier *)
  | Value of string option (* Value used in a memory access; argument: value *)

(** Type of an event action. *)
type event_action_type =
    Unknown
  | Timer
  | UserInterface
  | Network
  | Continuation

(** Happens-before edge in the hb graph. *)
type arc = { tail : int; head : int; duration : int; }

(** An event action, consisting of type and executed commands. *)
type event_action = { evtype : event_action_type; commands : command array; }

(** An event log, consisting of events and hb graph edges .*)
type event_log = { events : event_action array; arcs : arc array; }

(** [read_event_log filename] reads an event log from the given
    file. *)
val read_event_log : string -> event_log
