all: eventRacer.cma

OBJECTS=ActionLog.o StringSet.o Interface.o
CXXFLAGS=-g -O2 -fPIC -Wall -Wextra

eventRacer.cma eventRacer.cmxa: $(OBJECTS) eventRacer.ml
	ocamlmklib -o eventRacer $(OBJECTS) eventRacer.ml -lstdc++

clean:
	rm -f *.o *.cm* *.a *.so
