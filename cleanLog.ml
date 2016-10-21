open EventRacer

module BatIntHash = struct
  include BatInt
  let hash (x: int) = x
end

module IntOption = struct
  type t = int option
  let compare (x: int option) (y: int option) = match x, y with
    | Some x, Some y -> compare x y
    | Some _, None -> 1
    | None, Some _ -> -1
    | None, None -> 0
  let equal (x: int option) (y: int option) = x == y
  let default = None
end

module DependencyGraph =
  Graph.Persistent.Digraph.ConcreteBidirectionalLabeled(BatIntHash)(IntOption)

type command =
  | Read of reference * reference option
  | Write of reference * reference option
  | Post of int
  | Enter of reference
  | Exit

type event = {
  evtype: event_action_type;
  id: int;
  commands: command list
}

type trace = {
  events: event list;
  deps: DependencyGraph.t
}

let translate_arc { tail; head; duration } =
  if duration >= 0 then
    (tail, Some duration, head)
  else
    (tail, None, head)

let build_dependency_graph arcs =
  Array.fold_left
    (fun g a -> DependencyGraph.add_edge_e g (translate_arc a))
    DependencyGraph.empty arcs

let translate_event arcs id ({ evtype; commands }: EventRacer.event_action) =
  let rec translate i l =
    if i < Array.length commands then begin
      match commands.(i) with
        | Read_memory loc ->
            if i + 1 < Array.length commands then begin
              match commands.(i+1) with
                | Value value ->
                    translate (i+2) (Read (loc, Some value) :: l)
                | _ -> translate (i+1) (Read (loc, None) :: l)
            end else translate (i+1) (Read (loc, None) :: l)
        | Write_memory loc ->
            if i + 1 < Array.length commands then begin
              match commands.(i+1) with
                | Value value ->
                    translate (i+2) (Write (loc, Some value) :: l)
                | _ -> translate (i+1) (Write (loc, None) :: l)
            end else translate (i+1) (Write (loc, None) :: l)
        | Post id ->
            translate (i+1) (Post id :: l)
        | Enter_scope ref ->
            translate (i+1) (Enter ref :: l)
        | Exit_scope ->
            translate (i+1) (Exit :: l)
        | Value _ ->
            Format.eprintf "Unexpected value in event %d, command %d" id i;
            translate (i+1) l
    end else BatList.rev l
  in { evtype; id; commands = translate 0 [] }

let translate_events arcs events =
  BatArray.mapi (translate_event arcs) events |> BatArray.to_list

let translate_trace { events; arcs } =
  let deps = build_dependency_graph arcs
  in { events = translate_events arcs events; deps }

let irrelevant_scopes =
  Pcre.regexp ~study:true ~flags:[`ANCHORED]
    "(eh:mousemove|event:mouse(move|over|out))"
let irrelevant_location =
  Pcre.regexp ~study:true ~flags:[`ANCHORED]
    "(NodeTree:0x[0-9a-f]*|[0-9a-fx[]*]\\.mouse(move|over|out))"

let is_irrelevant_event { commands } =
  List.for_all
    (function
       | Enter (String (_, s)) -> Pcre.pmatch ~rex:irrelevant_scopes s
       | Exit -> true
       | Read (String (_, s), _) -> Pcre.pmatch ~rex:irrelevant_location s
       | Write (String (_, s), _) -> Pcre.pmatch ~rex:irrelevant_location s
       | _ -> false)
    commands

let filter_irrelevant_events { events; deps } =
  let compress_deps deps' { id } =
    if not (DependencyGraph.mem_vertex deps' id) then
      deps'
    else
      let deps'' = DependencyGraph.fold_pred_e
                     (fun (src, lbl1, _) deps' ->
                        DependencyGraph.fold_succ_e
                          (fun (_, lbl2, tgt) deps' ->
                             let lbl = match lbl1, lbl2 with
                               | Some lbl1, Some lbl2 -> Some (lbl1 + lbl2)
                               | _, None -> lbl1
                               | None, _ -> lbl2
                             in DependencyGraph.add_edge_e deps' (src, lbl, tgt))
                          deps id deps')
                     deps id deps'
      in DependencyGraph.remove_vertex deps'' id
  in let (irrelevant, relevant) = BatList.partition is_irrelevant_event events
  in { events = relevant; deps = List.fold_left compress_deps deps irrelevant }

let load_and_filter filename =
  EventRacer.read_event_log filename
    |> translate_trace
    |> filter_irrelevant_events
