all: eventRacer.cma dumpLog formatLog printCleanLog splitOutJS

OBJECTS=ActionLog.o StringSet.o Interface.o
CXXFLAGS=-g -O2 -fPIC -Wall -Wextra

eventRacer.cma eventRacer.cmxa: $(OBJECTS) eventRacer.ml
	ocamlmklib -o eventRacer $(OBJECTS) eventRacer.ml -lstdc++

install: eventRacer.cma META
	ocamlfind install event-racer META eventRacer.cma eventRacer.cmxa eventRacer.a dlleventRacer.so libeventRacer.a

uninstall:
	ocamlfind remove event-racer

reinstall: uninstall install

dumpLog: eventRacer.cma dumpLog.ml
	ocamlfind ocamlc -o $@ -package fmt -linkpkg eventRacer.cma dumpLog.ml

printCleanLog: eventRacer.cma cleanLog.ml printCleanLog.ml
	ocamlfind ocamlc -o $@ -package fmt -package ocamlgraph -package batteries -package pcre -linkpkg $^

splitOutJS: eventRacer.cma cleanLog.ml splitOutJS.ml
	ocamlfind ocamlc -o $@ -package fmt -package ocamlgraph -package batteries -package pcre -linkpkg $^

clean:
	rm -f *.o *.cm* *.a *.so
