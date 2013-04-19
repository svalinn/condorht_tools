#include <iostream>
#include <omp.h>

int main( int argc, char *argv[] )
{
  int thread_id; // thread id number
  int nthreads; // total number of threads
  #pragma omp parallel private(thread_id) shared(nthreads)
  {
    thread_id = omp_get_thread_num();
    #pragma omp critical // to ensure no overlaps
    {
      std::cout << "Hello World from thread " << thread_id << '\n';
    }
    #pragma omp barrier
 
    #pragma omp master
    {
      nthreads = omp_get_num_threads();
      std::cout << "There are " << nthreads << " threads" << '\n';
    }
  }
  return 0;
}
