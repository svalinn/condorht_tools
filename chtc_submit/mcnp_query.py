#!/usr/bin/python

# test for tetmesh information in file
# return true/false for tet_mesh in file
# return true/false for meshtal in file
# return true/false for mctal information
# recommend dumping schedule in none exists
def mcnp_input_query(mcnp_filename,tetmesh):

    tet_mesh_tf = False
    meshtal_tf = False
    mctal_tf = False

    fp = open(mcnp_filename,'r')
    while 1:
        line = fp.readline()
        if line.lower() == "geom=dag":
            tet_mesh_tf = True

        if line.lower() != "geom=dag" and line.lower() == "fmesh":
            meshtal_tf = True

        if line.lower() == "prdmp":
            mctal_tf = True
            
    fp.close()

    return (tet_mesh_tf,meshtal_tf,mctal_tf)

