################################################################################

universe = vanilla
executable = /home/mpich2/bin/mpiexec
arguments = -np 16 ./mpi_test
output = std.out
error = std.err
log = std.log
request_cpus = 16
request_memory = 1000
request_disk = 1e6
should_transfer_files = YES
when_to_transfer_output = ON_EXIT
notification = never
transfer_input_files = mpi_test
+AccountingGroup = "EngrPhysics_Wilson"
Queue
