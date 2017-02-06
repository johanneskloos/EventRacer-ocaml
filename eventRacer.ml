(* Public interface *)
type command =
  | Enter_scope of string option
  | Exit_scope
  | Read_memory of string option
  | Write_memory of string option
  | Post of int
  | Value of string option

type event_action_type =
  | Unknown
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

type access_type = Read | Write | Update
type race_info = {
  ri_access1: access_type;
  ri_access2: access_type;
  ri_event1: int;
  ri_event2: int;
  ri_cmd1: int;
  ri_cmd2: int;
  ri_var: int;
  ri_covered: int
}

type event_log = {
  events: event_action array;
  arcs: arc array;
  races: race_info array
}

(* Internal C++ interface *)
type log_ptr
type command_ptr
type internal_event = {
  ie_type: int;
  ie_num_cmds: int;
  ie_cmds: command_ptr
}
type internal_command = {
  ic_type: int;
  ic_arg: int
}
external load: string -> log_ptr = "caml_load"
external usable: log_ptr -> bool = "caml_usable"
external free: log_ptr -> unit = "caml_free"
external num_arcs: log_ptr -> int = "caml_num_arcs"
external num_events: log_ptr -> int = "caml_num_events"
external get_js: log_ptr -> int -> string = "caml_get_js"
external get_mem_value: log_ptr -> int -> string = "caml_get_mem_value"
external get_scope: log_ptr -> int -> string = "caml_get_scope"
external get_var: log_ptr -> int -> string = "caml_get_var"
external nth_event: log_ptr -> int -> internal_event = "caml_nth_event"
external nth_arc: log_ptr -> int -> arc = "caml_nth_arc"
external nth_command: command_ptr -> int -> internal_command = "caml_nth_command"
external num_races: log_ptr -> int = "caml_num_races"
external nth_race: log_ptr -> int -> race_info = "caml_nth_race"

let cached f log =
  let cache = Hashtbl.create 65537 in
  fun idx ->
    try Hashtbl.find cache idx
    with Not_found ->
      let res = f log idx
      in Hashtbl.add cache idx res; res

let evtypes = [| Unknown; Timer; UserInterface; Network; Continuation |]

let read_event_log filename =
  let log = load filename
  in if usable log then
    let arcs = Array.init (num_arcs log) (nth_arc log)
    and races = Array.init (num_races log) (nth_race log)
    and _ = cached get_js log
    and cached_mem_value = cached get_mem_value log
    and cached_scope = cached get_scope log
    and cached_var = cached get_var log
    in let events = Array.init (num_events log)
	   (fun i ->
	      let { ie_type; ie_num_cmds; ie_cmds } = nth_event log i
	      in let evtype = evtypes.(ie_type)
	      and commands = Array.init ie_num_cmds
		  (fun i ->
		     match nth_command ie_cmds i with
		     | { ic_type = 0; ic_arg = -1 } ->
		       Enter_scope None
		     | { ic_type = 0; ic_arg } ->
		       Enter_scope (Some (cached_scope ic_arg))
		     | { ic_type = 1 } ->
		       Exit_scope
		     | { ic_type = 2; ic_arg = -1 } ->
		       Read_memory None
		     | { ic_type = 2; ic_arg } ->
		       Read_memory (Some (cached_var ic_arg))
		     | { ic_type = 3; ic_arg = -1 } ->
		       Write_memory None
		     | { ic_type = 3; ic_arg } ->
		       Write_memory (Some (cached_var ic_arg))
		     | { ic_type = 4; ic_arg } ->
		       Post ic_arg
		     | { ic_type = 5; ic_arg = -1 } ->
		       Value None
		     | { ic_type = 5; ic_arg } ->
		       Value (Some (cached_mem_value ic_arg))
		     | _ -> raise Not_found)
       in { evtype; commands })
    in { arcs; events; races }
  else failwith ("Couldn't parse " ^ filename)

