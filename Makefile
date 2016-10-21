all: eventRacer.cma

OBJECTS=ActionLog.o StringSet.o Interface.o
CXXFLAGS=-g -O2 -fPIC

eventRacer.cma eventRacer.cmxa: $(OBJECTS) eventRacer.ml
	ocamlmklib -o eventRacer $(OBJECTS) eventRacer.ml

clean:
	rm -f *.o *.cm*
