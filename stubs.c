#include <caml/mlvalues.h>

CAMLprim value read_event_log(value filename);
CAMLprim value caml_read_event_log(value filename) {
    return read_event_log(filename);
}

