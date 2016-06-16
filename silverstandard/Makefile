SRC=src
BIN=bin
OBJ=obj
CXXFLAGS+=-I/usr/local/include

default: all
all: silverstandard

silverstandard: silverstandard.o
	mkdir -p $(BIN)
	$(CXX) $(LDFLAGS) -lexecinfo -lgomp -o $(BIN)/silverstandard $(OBJ)/silverstandard.o

silverstandard.o: $(SRC)/silverstandard.cpp
	mkdir -p $(OBJ)
	$(CXX) $(CXXFLAGS) -std=c++14  -fopenmp -DSEQAN_HAS_OPENMP=1 -DNDEBUG -O3 -c -o $(OBJ)/silverstandard.o $(SRC)/silverstandard.cpp

clean:
	rm -r $(OBJ)

.PHONY: default all clean
