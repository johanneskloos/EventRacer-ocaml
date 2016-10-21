LIBCXXSOURCES=Interface.cpp ActionLog.cpp StringSet.cpp
LIBOCAMLSOURCES=eventRacer.ml cleanLog.mli cleanLog.ml
PROGOCAMLSOURCES=dumpLog.ml printCleanLog.ml splitOutJS.ml
LIBCXXOBJECTS=$(patsubst %.cpp,%.o,$(LIBCXXSOURCES))
FINDOPTS=-package batteries -package fmt -package ocamlgraph -package pcre -linkpkg
LIBBASE=eventracer
PROGRAMS=$(patsubst %.ml,%,$(PROGOCAMLSOURCES))
CXXFLAGS:=$(CXXFLAGS) -fPIC -O2 -Wall -Wextra -g

all: $(LIBBASE).cma $(PROGRAMS)

$(LIBBASE).cma $(LIBBASE).cmxa $(LIBBASE).a dll$(LIBBASE).so: \
    $(LIBCXXOBJECTS) $(LIBOCAMLSOURCES)
	ocamlfind ocamlmklib $(FINDOPTS) -o $(LIBBASE) -oc $(LIBBASE) $^ -lstdc++

%: $(LIBBASE).cmxa %.ml
	ocamlfind ocamlopt -o $@ $^ $(FINDOPTS) -ccopt -L.

clean:
	rm -f *~ *.cm* *.o *.a *.so $(PROGRAMS)
