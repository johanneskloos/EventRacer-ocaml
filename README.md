# EventRacer-ocaml

TLDR: An OCaml API for the EventRacer action log file format.

The [[http://eventracer.org|EventRacer]] project provides instrumented browsers that output event traces of their operation.
These traces are extremely useful for building dynamic analyses of JavaScript and web pages; for instance,
EventRacer itself provides a race detection tool.

The file format used by EventRacer is a custom binary format (the action log), for which they provide a C++ API.
This project wraps the C++ API to provide an OCaml API for these files.

# Building

To build EventRacer-ocaml, you need a C++ compiler (tested with g++) and a recent OCaml compiler (4.03 works, 4.02 should be fine),
as well as the ocamlgraph and fmt OCaml packages.

If you use opam, install the dependencies with "opam install ocamlgraph fmt".
A simple "make" builds the library, and "make install" installs it using findlib.

If you don't use opam, you may have to adjust the Makefile to set OCAMLINCLUDE correctly.

# Using

The recommended way to use the library is using the CleanLog module. For an example, see dumpLog.ml.
