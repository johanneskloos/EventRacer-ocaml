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
#include <cstdio>

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

typedef std::vector<ActionLog::Command> commands;

void dump(const char *filename) {
    const Log *log = load(filename);
    for (int i = 0; i < log->m_actions.maxEventActionId(); i++) {
        const ActionLog::EventAction& a(log->m_actions.event_action(i));
        printf("Event %d:\n", i);
        for (commands::const_iterator it(a.m_commands.begin());
                it != a.m_commands.end(); it++) {
            switch (it->m_cmdType) {
                case ActionLog::ENTER_SCOPE:
                    printf("  Entering scope %s",
                            it->m_location < 0 ? "(unknown)" :
                            log->m_scopes.getString(it->m_location));
                    break;
                case ActionLog::READ_MEMORY:
                    printf("  Reading %s\n",
                            it->m_location < 0 ? "(unknown)" :
                            log->m_vars.getString(it->m_location));
                    break;
                case ActionLog::WRITE_MEMORY:
                    printf("  Writing %s\n",
                            it->m_location < 0 ? "(unknown)" :
                            log->m_vars.getString(it->m_location));
                    break;
                case ActionLog::MEMORY_VALUE:
                    printf("  Value %s\n",
                            it->m_location < 0 ? "(unknown)" :
                            log->m_memValues.getString(it->m_location));
                    break;
                case ActionLog::TRIGGER_ARC:
                    printf("  Posting %d\n", it->m_location);
                    break;
                case ActionLog::EXIT_SCOPE:
                    printf("  Exiting scope\n");
                    break;
            }
        }
    }
    delete log;
}

int main(int argc, const char *argv[]) {
    for (int i = 1; i < argc; i++) {
        dump(argv[i]);
    }
    return 0;
}
