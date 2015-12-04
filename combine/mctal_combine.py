#!/usr/bin/python
import subprocess
import sys
import os
import math
import datetime
'''two files in argv[1] and argv[2]'''

class Mctal(object):
    def __init__(self):
        self.nod = 0
        self.nps = 0 # int(words[1])
        self.rnr = 0 # int(words[2])
        self.comment = ''
        self.n_tallies=-1
        self.tally_nums=[]
        self.tally_line=[]
        self.fnum=[]
        self.flist=[]
        self.dnum = []
        self.unum = []
        self.snum = []
        self.mnum = []
        self.cnum = []
        self.enum = []
        self.tnum = []
        self.valList = []
        self.tfcNum = []
        self.tfcList=[]
        self.data = []
        self.slist = []
        self.clist = []
        self.elist = []
        self.tlist = []
        self.nvals = []
        self.kod=''
        self.ver='' 
        self.date=''
        self.time=''
        self.knod=''
        self.f=[]
        self.d=[]
        self.u=[]
        self.s=[]
        self.m=[]
        self.c=[]
        self.e=[]
        self.t=[]


    def read(self, filename):

        # open file
        try:
            self.file = open(filename, 'r')
        except IOError, (errno, strerror):
            print "Error Opening %s. (%s): %s"%(filename,errno, strerror)
            sys.exit(1)

        try:
            # get code name, version, date/time, etc
            words = self.file.readline().split()
            self.kod =words[0]
            self.ver = int(words[1])
            self.date= words[2]
            self.time= words[3]
            self.nod = int(words[4])
            self.nps = int(words[5])
            self.rnr = int(words[6])

            # comment line of input file
            self.comment = self.file.readline().strip()

            # read tally line
            words = self.file.readline().split()
            self.n_tallies = int(words[1])
            if len(words) > 2:
                # perturbation tallies present
                pass

            # read tally numbers
            self.tally_nums = [int(i) for i in self.file.readline().split()]
	    #print tally_nums
            # read tallies
            for i_tal in range(self.n_tallies):
                hold = [int(i) for i in self.file.readline().split()[1:]]
                self.tally_line.append(hold)
            
                tal_1=self.tally_line[i_tal-1][0]
                tal_2=self.tally_line[i_tal-1][1]
                tal_3=self.tally_line[i_tal-1][2]
                 

                fnum = 0
                flist = []
                dnum = 0
                unum = 0
                snum = 0
                mnum = 0
                cnum = 0
                enum = 0
                tnum = 0
                valList = []
                tfcNum = 0
                tfcList=[]
                slist = []
                clist = []
                elist = []
                tlist = []
                nvals = 0

	        line = self.file.readline().split()
                while line[0] != 'tfc': 
                    if 'f' in line[0]:
                        self.f.append(line[0])
                        fnum=int(line[1])
                        if tal_1%10 != 5:
                            while len(flist) != fnum:
                                flist+=[float(i) for i in self.file.readline().split()]
                            
                    elif 'd' in line[0]:
                        self.d.append(line[0])
                        dnum=int(line[1])
                    elif line[0]=='u' or line[0]=='ut' or line[0]=='uc':
                        self.u.append(line[0])
                        unum=int(line[1])
                    elif line[0]=='s' or line[0]=='st' or line[0]=='sc':
                        self.s.append(line[0])
                        snum=int(line[1])
                        if snum > 0 and tal_1%10 ==5:
                            while len(slist) != snum:
                                slist+=[float(i) for i in self.file.readline().split()]
                    elif line[0] =='m' or line[0]=='mt' or line[0]=='mc':
                        self.m.append(line[0])
                        mnum=int(line[1])
                    elif line[0] =='c' or line[0]=='ct' or line[0]=='cc' or line[0]=='r' or line[0]=='rt' or line[0]=='rc':
                        self.c.append(line[0])
                        cnum=int(line[1])
                        if cnum > 0 and tal_1%10!=5 and 'ct' in line[0]:
                            while len(clist) != cnum-1:
                                clist+=[float(i) for i in self.file.readline().split()]
                    elif line[0] =='e' or  line[0]=='et' or line[0]=='ec':
                        self.e.append(line[0])
                        enum=int(line[1])
                        if enum > 0 and 'et' in line[0]:
                            while len(elist) != enum -1:
                                elist+=[float(i) for i in self.file.readline().split()]
                    elif line[0] =='t' or line[0]=='tt' or line[0]=='tc':
                        self.t.append(line[0])
                        tnum=int(line[1])
                        if tnum > 0 and 'tt' in line[0]:
                            while len(tlist) != tnum -1:
                                tlist = [float(i) for i in self.file.readline().split()]
                    elif line[0] =='vals':
                        if fnum>0:
                            feffect = fnum
                        else:
                            feffect = 1
                        if dnum > 0:
                            deffect = dnum
                        else:
                            deffect = 1
                        if unum > 0:
                            ueffect = unum
                        else:
                            ueffect = 1
                        if snum > 0:
                            seffect = snum
                        else:
                            seffect = 1
                        if mnum > 0:
                            meffect = mnum
                        else:
                            meffect = 1
                        if cnum > 0:
                            ceffect = cnum
                        else:
                            ceffect = 1
                        if enum > 0:
                            eeffect = enum
                        else:
                            eeffect = 1
                        if tnum > 0:
                            teffect = tnum
                        else:
                            teffect = 1                    


                        nvals = 2*(feffect)*(deffect)*(ueffect)*(seffect)*(meffect)*(ceffect)\
                            *(eeffect)*(teffect)
                        while len(valList) != nvals:
                            valList+=[float(i) for i in self.file.readline().split()]
                    else:
                        print "error"+line[0]
                    line = self.file.readline().split()  
                
                tfcNum=int(line[1])
                tfcList=[int(i) for i in line[2:]]
                self.fnum.append(fnum)
                self.flist.append(flist)
                self.dnum.append(dnum)
                self.unum.append(unum)
                self.snum.append(snum)
                self.mnum.append(mnum)
                self.cnum.append(cnum)
                self.enum.append(enum)
                self.tnum.append(tnum)
                self.valList.append(valList)
                self.tfcNum.append(tfcNum)
                self.tfcList.append(tfcList)
                self.slist.append(slist)
                self.clist.append(clist)
                self.elist.append(elist)
                self.tlist .append(tlist)
                self.nvals.append(nvals)

                data = []
                for ndx in range(tfcNum):
                    vals=[float(i) for i in self.file.readline().split()]
                    data.append(vals)
                self.data.append(data)

            self.file.close()
        except Exception,inst:
            print "Error Reading %s.: %s" % (filename, inst.args)
            sys.exit(1)
          




    def Add(self,Other):
        
        if self.n_tallies != Other.n_tallies:
            print "Error"
            return
           
        #self.nps = self.nps + Other.nps
        #self.rnr = self.rnr + Other.rnr
        for i_tal in range(self.n_tallies):
            numvals = self.nvals[i_tal]
            for nval in range(0,numvals,2):
                #mean
                mean0 = self.valList[i_tal][nval]
                mean1 = Other.valList[i_tal][nval]
                mean = (self.nps * mean0 + Other.nps*mean1)/(self.nps+Other.nps)
                #error
                err0= self.valList[i_tal][nval+1]
                err1= Other.valList[i_tal][nval+1]
                t0 = self.nps*mean0*mean0*(err0*err0*(self.nps-1.0)+1)
                t1 = Other.nps*mean1*mean1*(err1*err1*(Other.nps-1.0)+1)
                err = 0
                if ((t0+t1)/(self.nps+Other.nps)-mean*mean)>0:
                    err = math.sqrt(((t0+t1)/(self.nps+Other.nps)-mean*mean)/(self.nps+Other.nps-1))/abs(mean)
                self.valList[i_tal][nval]=mean
                self.valList[i_tal][nval+1]=err
        
      #  print "NEW NVALS",self.valList
        self.nps = self.nps + Other.nps
        self.rnr = self.rnr + Other.rnr



    def Write(self,filename):
        try:
            file = open(filename,'w')
        except IOError, (errno, strerror):
            print "Error Opening outputfile. (%s): %s"%(errno, strerror)

        now = datetime.datetime.now()
        self.date = '%02d/%02d/%02d'%(now.month,now.day,now.year)
        self.time = '%02d:%02d:%02d'%(now.hour,now.minute,now.second)
        file.write("%8s %8s %10s %8s %8s %8s %8s\n"%(self.kod, self.ver,self.date, self.time, self.nod, self.nps, self.rnr))
        file.write(self.comment+'\n')
        file.write('ntal %6s\n'%(self.n_tallies))
        file.write('\t%5s\n'%('\t'.join(str(v) for v in self.tally_nums)))
        for i in range(self.n_tallies):
            file.write('tally    %5s\n'%('     '.join(str(v) for v in self.tally_line[i])))
            file.write('%2s %8s\n'%(self.f[i],self.fnum[i]))
            if len(self.flist[i]) > 0:
                file.write('\t%15s\n'%('\t'.join(str(v) for v in self.flist[i])))
            file.write('%2s %8s\n'%(self.d[i],self.dnum[i]))
            file.write('%2s %8s\n'%(self.u[i],self.unum[i]))
            file.write('%2s %8s\n'%(self.s[i],self.snum[i]))
            if len(self.slist[i]) > 0:
                file.write('\t%15s\n'%('\t'.join(str(v) for v in self.slist[i])))
            file.write('%2s %8s\n'%(self.m[i],self.mnum[i]))
            file.write('%2s %8s\n'%(self.c[i],self.cnum[i]))
            if len(self.clist[i]) > 0:
                file.write('\t%15s\n'%('\t'.join(str(v) for v in self.clist[i])))
    
            file.write('%2s %8s\n'%(self.e[i],self.enum[i]))
            if len(self.elist[i]) > 0:
                for vndx in range(int(math.ceil(len(self.elist[i])/8.0))):
                    file.write('  %15s\n'%(' '.join(str('%.5e'%(v)) for v in self.elist[i][8*vndx:8*(vndx+1)])))    

            file.write('%2s %8s\n'%(self.t[i],self.tnum[i]))
            if len(self.tlist[i]) > 0:
                file.write('\t%15s\n'%('\t'.join(str(v) for v in self.tlist[i])))
    
            file.write('vals\n')
            for vndx in range(int(math.ceil(len(self.valList[i])/8.0))):
                file.write('  %15s\n'%(' '.join(str('%.5e'%(v)) for v in self.valList[i][8*vndx:8*(vndx+1)])))
            file.write('tfc\t%s\t%s\n'%(self.tfcNum[i],'\t'.join(str(v) for v in self.tfcList[i])))
            for ndx in range(self.tfcNum[i]):
                file.write('   %8s  %s\n'%(int(self.data[i][ndx][0]),'  '.join(str('%.5e'%(v)) for v in self.data[i][ndx][1:])))
        file.close()



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
    print 'mctal_combine: A tool for combining MCNP mctal files\n'
    print 'python mctal_combine.py [OPTIONS] INPUT1 INPUT2 ...\n'
    print 'OPTIONS'
    print '-o OUTFILE\tSet Output file name to OUTFILE (default COMBINEDMESH)'
    print '-s\t\tStreaming Mode, for very large files'
    print '-d\t\tDelete input files after processing'
    print '-h\t\tHelp\n'





def main():

    #flags
    outname = CmdLineFind('-o','COMBINEDMCTAL')
    streaming = CmdLineFindIndex('-s');   
    delete = CmdLineFindIndex('-d');
    showHelp = CmdLineFindIndex('-h')
    #figure out where input data is (must be after flags)

    if showHelp>0:
        help()



    filesNdx = 1
    if CmdLineFindIndex('-o') > 0:
        filesNdx += 2
    if streaming > 0:
        filesNdx += 1
    if delete > 0:
        filesNdx+=1



    if len(sys.argv)-filesNdx < 2:
        print 'Error: Not enough files'
        help()
        sys.exit(1) 


    mcfiles = sys.argv[filesNdx:]
    if streaming>=0:
        print "Streaming not currently supported."
    mctal = Mctal()
    mctal.read(mcfiles[0])
    for ndx in range(1,len(mcfiles)):
        mctal2=Mctal()
        mctal2.read(mcfiles[ndx])
        print mcfiles[ndx]
        mctal.Add(mctal2)
    mctal.Write(outname)


if __name__ == "__main__":
    main()
