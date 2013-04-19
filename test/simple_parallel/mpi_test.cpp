#include <iostream>
#include "mpi.h"

void print_id(int id_number, int num_proc);

int main(int argc, char* argv[])
  {

  int id; // cpu id
  int p; // number of procs

  MPI::Init (argc,argv);

  id = MPI::COMM_WORLD.Get_rank( );
  p = MPI::COMM_WORLD.Get_size( );

  if ( id == 0 )
    {
      std::cout << " I am the master " << id << std::endl;
    }

  MPI::COMM_WORLD.Barrier( );

  print_id(id,p);

  MPI::COMM_WORLD.Barrier( );
  MPI::Finalize( );

  return 0;
}


void print_id(int id,int p)  
{
  std::cout << "I am processor " << id << " of " << p << std::endl;
  return;
}
