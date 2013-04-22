################################################################################

executable = /home/davisa/par_test/omp_test/omp_test
arguments = 1
universe  = vanilla
output = std.out
error = std.err
log = std.log
request_cpus = 8
copy_to_spool           = false
should_transfer_files   = yes
when_to_transfer_output = on_exit
+AccountingGroup = "EngrPhysics_Wilson"
Queue
