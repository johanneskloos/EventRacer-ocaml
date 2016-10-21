SOURCES=ActionLog.cpp StringSet.cpp Interface.cpp
OBJECTS=$(patsubst %.cpp,%.o,$(SOURCES))
CXXFLAGS=-fPIC -O2 -Wall -Wextra -g

library: $(OBJECTS)
	ocamlmklib -o eventracer $(OBJECTS) -lstdc++

clean:
	rm -f $(filter-out %.cpp, $(filter-out %.h, $(filter-out Makefile, $(wildcard *))))
