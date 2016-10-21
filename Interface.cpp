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

struct cached_string_set {
    const StringSet& _strings;
    std::map<int, value> _cache;
    cached_string_set(const StringSet &strings):
        _strings(strings) {}
    value to_value(int i) {
        std::map<int, value>::iterator it = _cache.find(i);
        if (it != _cache.end())
            return it->second;
        const char *val = _strings.getString(i);
        value result;
        if (val == nullptr) {
            result = caml_alloc(1, 1);
            Store_field(result, 0, Val_int(i));
        } else {
            result = caml_alloc(2, 0);
            Store_field(result, 0, Val_int(i));
            Store_field(result, 1, caml_copy_string(val));
        }
        _cache[i] = result;
        return result;
    }
};

struct log {
    StringSet m_vars;
    StringSet m_scopes;
    ActionLog m_actions;
    StringSet m_js;
    StringSet m_memValues;
};

struct open_exception: std::exception {};
struct read_exception: std::exception {};
struct parse_exception: std::exception {};

const log load(const char *filename) {
    log log;
    FILE* f = fopen(filename, "rb");
    if (!f)
        throw new open_exception();
    bool result = true;
    result &= log.m_vars.loadFromFile(f);
    result &= log.m_scopes.loadFromFile(f);
    result &= log.m_actions.loadFromFile(f);
    if (!feof(f)) {
        result &= log.m_js.loadFromFile(f);
    }
    if (!feof(f)) {
        result &= log.m_memValues.loadFromFile(f);
    }

    fclose(f);
    if (!result)
        throw new read_exception();
    return log;
}

value int_to_reference(cached_string_set& strings, int ref) {
    if (ref < 0) {
        return Val_int(0);
    } else {
        return strings.to_value(ref);
    }
}

struct strings {
    cached_string_set vars;
    cached_string_set scopes;
    cached_string_set js;
    cached_string_set memValues;
    strings (const log& l):
        vars(l.m_vars),
        scopes(l.m_scopes),
        js(l.m_js),
        memValues(l.m_memValues) {}
};


value parse_command(strings& strings, ActionLog::Command cmd) {
    int tag;
    switch (cmd.m_cmdType) {
        case ActionLog::ENTER_SCOPE:
            tag = 0; break;
        case ActionLog::READ_MEMORY:
            tag = 1; break;
        case ActionLog::WRITE_MEMORY:
            tag = 2; break;
        case ActionLog::TRIGGER_ARC:
            tag = 3; break;
        case ActionLog::MEMORY_VALUE:
            tag = 4; break;
        case ActionLog::EXIT_SCOPE:
            return Val_int(0);
        default:
            throw new parse_exception();
    }
    value result = caml_alloc(1, tag);
    Store_field(result, 0, int_to_reference(strings.scopes, cmd.m_location));
    return result;
}

value parse_arc(ActionLog::Arc a) {
    value result = caml_alloc_tuple(3);
    Store_field(result, 0, Val_int(a.m_tail));
    Store_field(result, 1, Val_int(a.m_head));
    Store_field(result, 2, Val_int(a.m_duration));
    return result;
}

value parse_event_action(strings& strings, const ActionLog::EventAction& e) {
    value result = caml_alloc_tuple(2);
    Store_field(result, 0, Val_int(e.m_type));
    value commands = caml_alloc_tuple(e.m_commands.size());
    Store_field(result, 1, commands);
    int i = 0;
    for (std::vector<ActionLog::Command>::const_iterator it = e.m_commands.begin();
            it != e.m_commands.end(); it++) {
        Store_field(commands, i++, parse_command(strings, *it));
    }
    return result;
}

value parse_event_log(strings& strings, const ActionLog& log) {
    value result = caml_alloc_tuple(2);
    value events = caml_alloc_tuple(log.maxEventActionId());
    Store_field(result, 0, events);
    for (int i = 0; i < log.maxEventActionId(); i++) {
        Store_field(events, i, parse_event_action(strings, log.event_action(i)));
    }
    const std::vector<ActionLog::Arc>& arcs_in(log.arcs());
    value arcs = caml_alloc_tuple(arcs_in.size());
    Store_field(result, 1, arcs);
    int i = 0;
    for (std::vector<ActionLog::Arc>::const_iterator it = arcs_in.begin();
            it != arcs_in.end(); it++, i++) {
        Store_field(arcs, i, parse_arc(*it));
    }
    return result;
}

extern "C" {
    CAMLprim value read_event_log(value filename) {
        try {
            log log(load(String_val(filename)));
            strings strings(log);
            return parse_event_log(strings, log.m_actions);
        } catch (open_exception e) {
            caml_raise_constant(*caml_named_value("open_exception"));
        } catch (read_exception e) {
            caml_raise_constant(*caml_named_value("read_exception"));
        } catch (parse_exception e) {
            caml_raise_constant(*caml_named_value("parse_exception"));
        }

    }
}
