CXX = mpicxx

# add -g -pg to both CXX and LD flags to profile

all: mpi_test

mpi_test: mpi_test.cpp
	$(CXX) mpi_test.cpp -o mpi_test

clean:
	rm -f mpi_test.o mpi_test
