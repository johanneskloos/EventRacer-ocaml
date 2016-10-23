/*
   Copyright 2013 Software Reliability Lab, ETH Zurich
   and 2016 MPI-SWS

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
 */

#include <vector>
#include <stdio.h>
#include <exception>
#include <map>
#include "StringSet.h"
#include "ActionLog.h"
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/callback.h>

struct Log {
    StringSet m_vars;
    StringSet m_scopes;
    ActionLog m_actions;
    StringSet m_js;
    StringSet m_memValues;
};

const Log *load(const char *filename) {
    Log *log = new Log();
    FILE* f = fopen(filename, "rb");
    if (!f)
	return nullptr;
    bool result = true;
    result &= log->m_vars.loadFromFile(f);
    result &= log->m_scopes.loadFromFile(f);
    result &= log->m_actions.loadFromFile(f);
    if (!feof(f)) {
        result &= log->m_js.loadFromFile(f);
    }
    if (!feof(f)) {
        result &= log->m_memValues.loadFromFile(f);
    }

    fclose(f);
    if (!result)
        return nullptr;
    return log;
}

inline const Log *log_ptr(value log) {
    return (Log *)(Field(log, 0));
}

inline const ActionLog::Command *commands_ptr(value cmds) {
    return (ActionLog::Command *)(Field(cmds, 0));
}

extern "C" {
    CAMLprim value caml_load(value filename) {
	CAMLparam1(filename);
	CAMLlocal1(result);
	const Log *log = load(String_val(filename));
	result = caml_alloc(1, Abstract_tag);
	Store_field(result, 0, (value)log);
	CAMLreturn(result);
    }

    CAMLprim value caml_usable(value log) {
	CAMLparam1(log);
	CAMLreturn(Val_bool(log_ptr(log) != nullptr));
    }

    CAMLprim void caml_free(value log) {
	CAMLparam1(log);
	delete ((Log *)(Field(log, 0)));
	CAMLreturn0;
    }

    CAMLprim value caml_num_events(value log) {
	CAMLparam1(log);
	CAMLreturn(Val_int(log_ptr(log)->m_actions.maxEventActionId()));
    }

    CAMLprim value caml_num_arcs(value log) {
	CAMLparam1(log);
	CAMLreturn(Val_int(log_ptr(log)->m_actions.arcs().size()));
    }

    CAMLprim value caml_nth_event(value _log, value idx) {
	CAMLparam2(_log, idx);
	CAMLlocal2(result, vec);
	const Log *log = log_ptr(_log);
	const ActionLog::EventAction& a(log->m_actions.event_action(Int_val(idx)));
	result = caml_alloc_tuple(3);
	vec = caml_alloc(1, Abstract_tag);
	Store_field(vec, 0, (value)a.m_commands.data());
	Store_field(result, 0, Val_int(a.m_type));
	Store_field(result, 1, Val_int(a.m_commands.size()));
	Store_field(result, 2, vec);
	CAMLreturn(result);
    }

    CAMLprim value caml_nth_arc(value _log, value idx) {
	CAMLparam2(_log, idx);
	CAMLlocal1(result);
	const Log *log = log_ptr(_log);
	const ActionLog::Arc& a(log->m_actions.arcs()[Int_val(idx)]);
	result = caml_alloc_tuple(3);
	Store_field(result, 0, Val_int(a.m_tail));
	Store_field(result, 1, Val_int(a.m_head));
	Store_field(result, 2, Val_int(a.m_duration));
	CAMLreturn(result);
    }

    CAMLprim value caml_nth_command(value _commands, value _idx) {
    	CAMLparam2(_commands, _idx);
	CAMLlocal1(result);
	int idx = Int_val(_idx);
	const ActionLog::Command *cmd = commands_ptr(_commands);
	result = caml_alloc_tuple(2);
	Store_field(result, 0, Val_int(cmd[idx].m_cmdType));
	Store_field(result, 1, Val_int(cmd[idx].m_location));
	CAMLreturn(result);
    }

    CAMLprim value caml_get_var(value _log, value _idx) {
	CAMLparam2(_log, _idx);
	int idx = Int_val(_idx);
	const Log *log = log_ptr(_log);
	CAMLreturn(caml_copy_string(log->m_vars.getString(idx)));
    }

    CAMLprim value caml_get_scope(value _log, value _idx) {
	CAMLparam2(_log, _idx);
	int idx = Int_val(_idx);
	const Log *log = log_ptr(_log);
	CAMLreturn(caml_copy_string(log->m_scopes.getString(idx)));
    }

    CAMLprim value caml_get_js(value _log, value _idx) {
	CAMLparam2(_log, _idx);
	int idx = Int_val(_idx);
	const Log *log = log_ptr(_log);
	CAMLreturn(caml_copy_string(log->m_js.getString(idx)));
    }

    CAMLprim value caml_get_mem_value(value _log, value _idx) {
	CAMLparam2(_log, _idx);
	int idx = Int_val(_idx);
	const Log *log = log_ptr(_log);
	CAMLreturn(caml_copy_string(log->m_memValues.getString(idx)));
    }
}
