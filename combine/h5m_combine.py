#!/usr/bin/python

import sys
from itaps import iBase,iMesh,iGeom

def load_mesh(filename):
    mesh = iMesh.Mesh() # imesh instance
    mesh.load(filename)
    num_el=mesh.getNumOfType(iBase.Type.all)
    return num_el,mesh

def get_volumes(mesh):
    volumes = list(mesh.iterate(iBase.Type.region, iMesh.Topology.all))
    return volumes

def combine_results(volumes,mesh1,mesh2):
    for volume in volumes:
        r1=mesh1.getTagHandle('TALLY_TAG')[volume]
        r2=mesh2.getTagHandle('TALLY_TAG')[volume]

        mesh1.getTagHandle('TALLY_TAG')[volume] = r1+r2
#        print mesh1.getTagHandle('TALLY_TAG')[volume]
    return mesh1

def save_mesh(mesh1,filename):
    mesh1.save(filename)
    return;

def CmdLineFindIndex( tag ):
    for i in range(len(sys.argv)):
        if sys.argv[i] == tag:		
            return i
    return -1

def CmdLineFind( tag, defaultvalue ):
    i = CmdLineFindIndex(tag)
    if i > 0:
        if i < len(sys.argv)-1:
            return sys.argv[i+1]
    return defaultvalue

def help():
    print 'h5m_combine: A tool for combining h5m files\n'
    print 'python h5m_combine.py [OPTIONS] INPUT1 INPUT2 ...\n'
    print 'OPTIONS'
    print '-o OUTFILE\tSet Output file name to OUTFILE (default COMBINED.h5m)'
    print '-d\t\tDelete input files after processing'
    print '-h\t\tHelp\n'




def main():

    #flags
    outname = CmdLineFind('-o','COMBINED.h5m')
    delete = CmdLineFindIndex('-d');
    showHelp = CmdLineFindIndex('-h')
    
    if showHelp > 0:
        help()
        sys.exit(1)        

    #figure out where input data is (must be after flags)

    filesNdx = 1
    if CmdLineFindIndex('-o') > 0:
        filesNdx += 2
    if delete > 0:
        filesNdx+=1
 
    if len(sys.argv)-filesNdx < 2:
        print 'Error: Not enough files'
        help()
        sys.exit(1) 

    h5mfiles = sys.argv[filesNdx:]


    (num_el1,mesh1) = load_mesh(h5mfiles[0])
    volumes = get_volumes(mesh1)
    for ndx in range(1,len(h5mfiles)):
        (num_el2,mesh2)=load_mesh(h5mfiles[ndx])
        mesh1=combine_results(volumes,mesh1,mesh2)
    save_mesh(mesh1,outname)

if __name__ == "__main__":
    main()


