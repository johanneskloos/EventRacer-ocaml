all: eventRacer.cma

OBJECTS=ActionLog.o StringSet.o Interface.o
CXXFLAGS=-g -O2 -fPIC -Wall -Wextra

eventRacer.cma eventRacer.cmxa: $(OBJECTS) eventRacer.ml
	ocamlmklib -o eventRacer $(OBJECTS) eventRacer.ml -lstdc++

install: eventRacer.cma META
	ocamlfind install event-racer META eventRacer.cma eventRacer.cmxa eventRacer.a dlleventRacer.so libeventRacer.a

uninstall:
	ocamlfind remove event-racer

reinstall: uninstall install

clean:
	rm -f *.o *.cm* *.a *.so
