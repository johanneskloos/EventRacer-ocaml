LIBCXXSOURCES=Interface.cpp
LIBOCAMLSOURCES=eventRacer.mli eventRacer.ml cleanLog.mli cleanLog.ml
LIBOCAMLIFS=$(patsubst %.ml,%.cmi,$(LIBOCAMLSOURCES))
LIBCMXFILES=$(patsubst %.ml,%.cmx,$(filter-out %.mli,$(LIBOCAMLSOURCES)))
PROGOCAMLSOURCES=dumpLog.ml
LIBCXXOBJECTS=$(patsubst %.cpp,%.o,$(LIBCXXSOURCES))
FINDOPTS=-package fmt -package ocamlgraph
LIBBASE=eventracer
PROGRAMS=$(patsubst %.ml,%,$(PROGOCAMLSOURCES))
OCAMLINCLUDE=$(shell opam config list | awk '$$1 == "lib" {print $$2}')/ocaml
EVENTRACER=/home/jkloos/workspace/EventRacer

CXXFLAGS:=$(CXXFLAGS) -fPIC -O2 -Wall -Wextra -g -I $(OCAMLINCLUDE) \
    -I $(EVENTRACER)/src/eventracer/input

all: $(LIBBASE).cma $(PROGRAMS)

$(LIBBASE).cma $(LIBBASE).cmxa $(LIBBASE).a dll$(LIBBASE).so: \
    $(LIBCXXOBJECTS) $(LIBOCAMLSOURCES)
	ocamlfind ocamlmklib $(FINDOPTS) -o $(LIBBASE) -oc $(LIBBASE) $^ \
	    -L $(EVENTRACER)/bin/eventracer/input -leventracer_input \
	    -lstdc++

%: $(LIBBASE).cmxa %.ml
	ocamlfind ocamlopt -o $@ $^ $(FINDOPTS) -ccopt -L. -linkpkg

clean:
	rm -f *~ *.cm* *.o *.a *.so $(PROGRAMS)

install: $(LIBBASE).cma
	ocamlfind install eventracer META *.a *.so $(LIBBASE).cma $(LIBBASE).cmxa $(LIBOCAMLIFS) $(LIBCMXFILES)

remove:
	ocamlfind remove eventracer

reinstall: remove install
