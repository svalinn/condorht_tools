#!/usr/bin/python
import subprocess
import datetime
import sys
import os
import math

class Meshtal(object):
    def __init__(self):
        self.file = None
        self.vers = -1
        self.ld=0
        self.numHist=-1
        self.comment=[]
        self.meshtalNum=[]
        self.type=[]
        self.xBounds = []
        self.yBounds = []
        self.zBounds = []
        self.enBounds= []
        self.enData = []
        self.xData = []
        self.yData = []
        self.zData = []
        self.resData=[]
        self.errData=[]
        self.filename=''
        self.enNdx =[]
        self.xNdx  =[]
        self.yNdx  =[]
        self.zNdx  =[]
        self.resNdx=[]
        self.errNdx=[]


    def read(self,filename):

        try:
            self.file = open(filename, 'r')
        except IOError, (errno, strerror):
            print "Error Opening %s. (%s): %s" % (filename,errno, strerror)
            sys.exit(1)

        try:
            self.filename=filename
            print "Reading "+filename
            words = self.file.readline().split()
            self.vers=int(words[2])
            self.ld=str(words[3][3:])
            self.comment=self.file.readline()
            words = self.file.readline().split()
            self.numHist=float(words[-1])
            self.file.readline()
            line = self.file.readline() 
            while len(line) != 0 :
                words = line.split()
                self.meshtalNum.append(int(words[-1]))
                type = self.file.readline()
                line = self.file.readline()

                while "Tally bin boundaries:" not in line:
                    type += line
                    line = self.file.readline()
               
                self.type.append(type)

                words   = self.file.readline().split()
                xBounds = [float(v) for v in words[2:]]
                words   = self.file.readline().split()
                yBounds = [float(v) for v in words[2:]]
                words   = self.file.readline().split()
                zBounds = [float(v) for v in words[2:]]
                words   = self.file.readline().split()
                enBounds= [float(v) for v in words[3:]]

                self.file.readline().split()
                dataOrder=self.file.readline().split()

                enNdx = -1
                xNdx = -1
                yNdx = -1
                zNdx = -1
                resNdx = -1
                errNdx = -1

                for ndx in range(len(dataOrder)):
                    if "Energy" in dataOrder[ndx]:
                        enNdx = ndx
                    elif "X" in dataOrder[ndx]:
                        xNdx=ndx
                    elif "Y" in dataOrder[ndx]:
                        yNdx=ndx
                    elif "Z" in dataOrder[ndx]:
                        zNdx=ndx
                    elif "Result" in dataOrder[ndx]:
                        resNdx=ndx
                    elif "Rel" in dataOrder[ndx]:
                        errNdx=ndx

                numData = (len(xBounds)-1)*(len(yBounds)-1)*(len(zBounds)-1)*(len(enBounds)-1)
                enData = []
                xData  = []
                yData  = []
                zData  = []
                resData= []
                errData= []
                for ndx in range(numData):
                    words = self.file.readline().split()
                    if len(words) > 0:
                        if enNdx >= 0:
                            enData.append(words[self.enNdx])
                        if xNdx >= 0:
                            xData.append( float(words[xNdx]))
                        if yNdx >= 0:
                            yData.append( float(words[yNdx]))
                        if zNdx >= 0:
                            zData.append( float(words[zNdx]))
                        resData.append(float(words[resNdx]))
                        errData.append(float(words[errNdx]))
                
                self.xBounds.append( xBounds )
                self.yBounds.append( yBounds )
                self.zBounds.append( zBounds )
                self.enBounds.append(enBounds)
                self.enData.append(  enData  )
                self.xData.append(   xData   )
                self.yData.append(   yData   )
                self.zData.append(   zData   )
                self.resData.append( resData ) 
                self.errData.append( errData )
                self.enNdx.append(   enNdx   )
                self.xNdx.append(    xNdx    )
                self.yNdx.append(    yNdx    )
                self.zNdx.append(    zNdx    )
                self.resNdx.append(  resNdx  )
                self.errNdx.append(  errNdx  )
                
                self.file.readline()
                line = self.file.readline()
        except Exception,inst:
            print "Error Opening %s.: %s" % (filename, inst.args)
            sys.exit(1)

        self.file.close()

    def Validate_op(self,Other):
        #check that files can be validly added together
        if self.vers != Other.vers:
            print 'Versions do not match '+self.filename+': '+str(self.vers)+', '+Other.filename+': '+str(Other.vers)
            return False 
        if self.ld != Other.ld:
            print 'ld do not match '+self.filename+': '+str(self.ld)+', '+Other.filename+': '+str(Other.ld)
            return False

        for ndx in range(len(self.type)):
            if self.meshtalNum[ndx] != Other.meshtalNum[ndx]:
                print 'Meshtally Numbers do not match '+self.filename+': '+str(self.meshtalNum[ndx])+', '+Other.filename+': '+str(Other.meshtalNum[ndx])
                return False

            if self.type[ndx] != Other.type[ndx]:
                print 'Types do not match '+self.filename+': '+self.type[ndx]+'\n'+Other.filename+': '+Other.type[ndx]
                return False

            if self.xBounds[ndx] != Other.xBounds[ndx]:
                print 'X Bounds for tally number '+str(self.meshtalNum[ndx])+' do not match '
                return False

            if self.yBounds[ndx] != Other.yBounds[ndx]:
                print 'Y Bounds for tally number '+str(self.meshtalNum[ndx])+' do not match '
                return False

            if self.zBounds[ndx] != Other.zBounds[ndx]:
                print 'Z Bounds for tally number '+str(self.meshtalNum[ndx])+' do not match '
                return False

            if self.enBounds[ndx] != Other.enBounds[ndx]:
                print 'Energy Bounds for tally number '+str(self.meshtalNum[ndx])+' do not match '
                return False

            if self.xNdx[ndx] != Other.xNdx[ndx] or self.yNdx[ndx] != Other.yNdx[ndx] or self.zNdx[ndx] != Other.zNdx[ndx] or self.enNdx[ndx] != Other.enNdx[ndx]:
                print 'Data is ordered differently for tally number '+str(self.meshtalNum[ndx])
                return False

            return True

    def Sub(self,Other):

        if not self.Validate_op(Other):
            return
        N = self.numHist+Other.numHist

        for ndx in range(len(self.type)):

            numData = (len(self.xBounds[ndx])-1)*(len(self.yBounds[ndx])-1)*(len(self.zBounds[ndx])-1)*(len(self.enBounds[ndx])-1)
            for num in range((numData)):
                R1 = self.resData[ndx][num]
                R2 = Other.resData[ndx][num]
                E1 = self.errData[ndx][num]
                E2 = Other.errData[ndx][num]
                self.resData[ndx][num] = R1-R2
                if self.resData[ndx][num] == 0:
                    self.errData[ndx][num] = 0
                else:
                    self.errData[ndx][num] = math.sqrt((R1*E1)**2+(R2*E2)**2)/(R1-R2)

        self.numHist = N
                    
    def Add(self,Other):

        if not self.Validate_op(Other):
            return

        N = self.numHist+Other.numHist
        for ndx in range(len(self.type)):

            numData = (len(self.xBounds[ndx])-1)*(len(self.yBounds[ndx])-1)*(len(self.zBounds[ndx])-1)*(len(self.enBounds[ndx])-1)
            for num in range((numData)):
                R1 = self.resData[ndx][num]
                R2 = Other.resData[ndx][num]
                E1 = self.errData[ndx][num]
                E2 = Other.errData[ndx][num]
                self.resData[ndx][num] = R1+R2
                if self.resData[ndx][num] == 0:
                    self.errData[ndx][num] = 0
                else:
                    self.errData[ndx][num] = math.sqrt((R1*E1)**2+(R2*E2)**2)/(R1+R2)
            
        self.numHist = N
            
    def Avg(self,Other):

        if not self.Validate_op(Other):
            return

        N = self.numHist+Other.numHist
        for ndx in range(len(self.type)):

            numData = (len(self.xBounds[ndx])-1)*(len(self.yBounds[ndx])-1)*(len(self.zBounds[ndx])-1)*(len(self.enBounds[ndx])-1)
            for num in range((numData)):
                S1 = self.resData[ndx][num]*self.numHist
                S2 = Other.resData[ndx][num]*Other.numHist
                T1 = self.numHist*self.resData[ndx][num]*self.resData[ndx][num]
                T1 = T1*(self.numHist*self.errData[ndx][num]*self.errData[ndx][num]+1)
                T2 = Other.numHist*Other.resData[ndx][num]*Other.resData[ndx][num]
                T2 = T2*(Other.numHist*Other.errData[ndx][num]*Other.errData[ndx][num]+1)
                mean = (S1+S2)/N
                stddev2=((T1+T2)/N-mean*mean)/N
                self.resData[ndx][num] = mean
                if mean ==0:
                    self.errData[ndx][num]=0
                else:
                    self.errData[ndx][num] = math.sqrt(stddev2)/mean
            
        self.numHist = N


    def Write(self,filename):        
        try:
            file = open(filename,'w')
        except IOError, (errno, strerror):
            print "Error Opening %s. (%s): %s" % (filename,errno, strerror)

        now = datetime.datetime.now()
        self.date = '%02d/%02d/%02d'%(now.month,now.day,now.year)
        self.time = '%02d:%02d:%02d'%(now.hour,now.minute,now.second)
        file.write('mcnp   version %s\tld=%s  probid = %s %s\n'%(self.vers,self.ld,self.date,self.time))
        file.write('%s'%(self.comment))
        file.write(' Number of histories used for normalizing tallies =\t%.5e\n'%(self.numHist))
        
        for ndx in range(len(self.meshtalNum)):
            file.write('\n Mesh Tally Number   %s\n'%(self.meshtalNum[ndx]))
            file.write(self.type[ndx])
            file.write(' Tally bin boundaries:\n')
            file.write('    X direction:%s\n'%(''.join(str('%10.2f'%(v)) for v in self.xBounds[ndx])))
            file.write('    Y direction:%s\n'%(''.join(str('%10.2f'%(v)) for v in self.yBounds[ndx])))
            file.write('    Z direction:%s\n'%(''.join(str('%10.2f'%(v)) for v in self.zBounds[ndx])))
            file.write('    Energy bin boundaries:%s\n'%(''.join(str('%9.2e'%(v)) for v in self.enBounds[ndx])))
            file.write('\n')
            if self.enNdx[ndx] >= 0:
                file.write('     Energy')
            if self.xNdx[ndx] >= 0:
                file.write('        X')
            if self.yNdx[ndx] >= 0:
                file.write('         Y')
            if self.zNdx[ndx] >= 0:
                file.write('         Z')


            file.write('     Result     Rel Error\n')

            numData = (len(self.xBounds[ndx]) - 1)
            numData *= (len(self.yBounds[ndx]) - 1)
            numData *= (len(self.zBounds[ndx]) - 1)
            numData *= (len(self.enBounds[ndx])- 1)
            for num in range(numData):
                if self.enNdx[ndx] >=0:
                    file.write('%10s'%(self.enData[ndx][num]))
                if self.xNdx[ndx] >=0:
                    file.write(' %10.3f'%(self.xData[ndx][num]))
                if self.yNdx[ndx] >=0:
                    file.write(' %9.3f'%(self.yData[ndx][num]))
                if self.zNdx[ndx] >=0:
                    file.write(' %9.3f'%(self.zData[ndx][num]))
                file.write(' %10.5e'%(self.resData[ndx][num]))
                file.write(' %10.5e\n'%(self.errData[ndx][num]))
        file.close()

def Stream(in1,in2,outname,op = ""):
    print in1+' '+in2+' '+outname
    mesh1 = Meshtal()
    mesh2 = Meshtal()

    try:
        mesh1.file = open(in1,'r')
    except IOError, (errno, strerror):
        print "Error Opening %s. (%s): %s" % (in1,errno, strerror)
        sys.exit(1)
    try:
        mesh2.file = open(in2,'r')     
    except IOError, (errno, strerror):
        print "Error Opening %s. (%s): %s" % (in2,errno, strerror)
        sys.exit(1)

    #mesh1 header
    try:
        words1 = mesh1.file.readline().split()
        mesh1.vers=int(words1[2])
        mesh1.ld=str(words1[3][3:])
        mesh1.comment=mesh1.file.readline()
        words1 = mesh1.file.readline().split()
        mesh1.numHist=float(words1[-1])

        mesh1.file.readline()
        line1 = mesh1.file.readline() 
    except Exception,inst:
        print "Error Reading %s.: %s" % (in1, inst.args)
        sys.exit(1)


    #mesh2 header
    try:
        words2 = mesh2.file.readline().split()
        mesh2.vers=int(words2[2])
        mesh2.ld=str(words2[3][3:])
        mesh2.comment=mesh2.file.readline()
        words2 = mesh2.file.readline().split()
        mesh2.numHist=float(words2[-1])

        mesh2.file.readline()
        line2 = mesh2.file.readline() 
    except Exception,inst:
        print "Error Reading %s.: %s" % (in2, inst.args)
        sys.exit(1)



    if mesh1.vers != mesh2.vers:
        print 'Versions do not match '+in1+': '+str(mesh1.vers)+', '+in2+': '+str(mesh2.vers)
        sys.exit(1)


    if mesh1.ld != mesh2.ld:
        print 'ld do not match '+in1+': '+str(mesh1.ld)+', '+in2+': '+str(mesh2.ld)


    try:
        file = open(outname,'w')
    except IOError, (errno, strerror):
        print "Error Opening %s. (%s): %s" % (outname,errno, strerror)
        sys.exit(1)


    now = datetime.datetime.now()
    date = '%02d/%02d/%02d'%(now.month,now.day,now.year)
    time = '%02d:%02d:%02d'%(now.hour,now.minute,now.second)

    try:
        file.write('mcnp   version %s\tld=%s  probid = %s %s\n'%(mesh1.vers,mesh1.ld,date,time))
        file.write('%s'%(mesh1.comment))
        file.write(' Number of histories used for normalizing tallies =\t%.5e\n'%(mesh1.numHist +mesh2.numHist))
    except Exception,inst:
        print "Error Writing %s.: %s" % (outname, inst.args)
        sys.exit(1)




    while len(line1) != 0 :
        try:
            words1 = line1.split()
            meshtalNum = int(words1[-1])
        except Exception,inst:
            print "Error Reading %s.: %s" % (in1, inst.args)
            sys.exit(1)


        try:
            words2 = line2.split()
            meshtalNum2 = int(words2[-1])
        except Exception,inst:
            print "Error Opening %s.: %s" % (in2, inst.args)
            sys.exit(1)



        if meshtalNum != meshtalNum2:
            print 'Meshtally Numbers do not match '+in1+': '+str(meshtalNum)+', '+in2+': '+str(meshtalNum2)
            sys.exit(1)
        
        file.write('\n Mesh Tally Number   %s\n'%(meshtalNum))

        try:
            type = mesh1.file.readline()
            line1 = mesh1.file.readline()
        except Exception,inst:
            print "Error Reading %s.: %s" % (in1, inst.args)
            sys.exit(1)

        try:
            type2 = mesh2.file.readline()
            line2 = mesh2.file.readline()
        except Exception,inst:
            print "Error Reading %s.: %s" % (in2, inst.args)
            sys.exit(1)



        while "Tally bin boundaries:" not in line1 and "Tally bin boundaries:" not in line2:
            type += line1
            line1 = mesh1.file.readline()
            type2+= line2
            line2 = mesh2.file.readline()

        if type != type2:
            print 'Types do not match '+in1+': '+type+'\n'+in2+': '+type2
            sys.exit(1)



        file.write(type)

        # self.type.append(type)
        file.write(' Tally bin boundaries:\n')
        try:
            words1 = mesh1.file.readline().split()
            words2  = mesh2.file.readline().split()

            xBounds = [float(v) for v in words1[2:]]
            xBounds2= [float(v) for v in words2[2:]]
            if xBounds != xBounds2:
                print 'X Bounds for tally number '+str(meshtalNum)+' do not match '
                sys.exit(1)

            words1 = mesh1.file.readline().split()
            words2 = mesh2.file.readline().split()

            yBounds = [float(v) for v in words1[2:]]
            yBounds2= [float(v) for v in words2[2:]]
            if yBounds != yBounds2:
                print 'Y Bounds for tally number '+str(meshtalNum)+' do not match '
                sys.exit(1)

            words1 = mesh1.file.readline().split()
            words2 = mesh2.file.readline().split()

            zBounds = [float(v) for v in words1[2:]]
            zBounds2= [float(v) for v in words2[2:]]
            if zBounds != zBounds2:
                print 'Z Bounds for tally number '+str(meshtalNum)+' do not match '
                sys.exit(1)

            words1 = mesh1.file.readline().split()
            words2 = mesh2.file.readline().split()

            enBounds= [float(v) for v in words1[3:]]
            enBounds2= [float(v) for v in words2[3:]]
            if enBounds != enBounds2:
                print 'Energy Bounds for tally number '+str(meshtalNum)+' do not match '
                sys.exit(1)

            mesh1.file.readline()
            mesh2.file.readline()
        
            dataOrder =mesh1.file.readline().split()
            dataOrder2=mesh2.file.readline().split()
        
            enNdx = -1
            xNdx = -1
            yNdx = -1
            zNdx = -1
            resNdx = -1
            errNdx = -1

            for ndx in range(len(dataOrder)):
                if "Energy" in dataOrder[ndx]:
                    enNdx = ndx
                elif "X" in dataOrder[ndx]:
                    xNdx=ndx
                elif "Y" in dataOrder[ndx]:
                    yNdx=ndx
                elif "Z" in dataOrder[ndx]:
                    zNdx=ndx
                elif "Result" in dataOrder[ndx]:
                    resNdx=ndx
                elif "Rel" in dataOrder[ndx]:
                    errNdx=ndx



            enNdx2 = -1
            xNdx2 = -1
            yNdx2 = -1
            zNdx2 = -1
            resNdx2 = -1
            errNdx2 = -1

            for ndx in range(len(dataOrder2)):
                if "Energy" in dataOrder2[ndx]:
                    enNdx2 = ndx
                elif "X" in dataOrder2[ndx]:
                    xNdx2=ndx
                elif "Y" in dataOrder2[ndx]:
                    yNdx2=ndx
                elif "Z" in dataOrder2[ndx]:
                    zNdx2=ndx
                elif "Result" in dataOrder2[ndx]:
                    resNdx2=ndx
                elif "Rel" in dataOrder2[ndx]:
                    errNdx2=ndx

            if xNdx != xNdx2 or yNdx != yNdx2 or zNdx != zNdx2 or enNdx != enNdx2:
                print 'Data is ordered differently for tally number '+str(meshtalNum)
                sys.exit(1)




            numData = (len(xBounds)-1)*(len(yBounds)-1)*(len(zBounds)-1)*(len(enBounds)-1)

            file.write('    X direction:%s\n'%(''.join(str('%10.2f'%(v)) for v in xBounds)))
            file.write('    Y direction:%s\n'%(''.join(str('%10.2f'%(v)) for v in yBounds)))
            file.write('    Z direction:%s\n'%(''.join(str('%10.2f'%(v)) for v in zBounds)))
            file.write('    Energy bin boundaries:%s\n'%(''.join(str('%9.2e'%(v)) for v in enBounds)))
            file.write('\n')
            if enNdx>= 0:
                file.write('     Energy')
            if xNdx >= 0:
                file.write('        X')
            if yNdx >= 0:
                file.write('         Y')
            if zNdx >= 0:
                file.write('         Z')

            file.write('     Result     Rel Error\n')

            for ndx in range(numData):
                words1 = mesh1.file.readline().split()
                words2 = mesh2.file.readline().split()
                if len(words1) > 0:
                    if enNdx >= 0:
                        enData1 = words1[enNdx]
                        enData2 = words2[enNdx]
                    if xNdx >= 0:
                        xData1 = float(words1[xNdx])
                        xData2 = float(words2[xNdx])
                    if yNdx >= 0:
                        yData1 = float(words1[yNdx])
                        yData2 = float(words2[yNdx])
                    if zNdx >= 0:
                        zData1 =  float(words1[zNdx])
                        zData2 = float(words2[zNdx])
                    resData1=float(words1[resNdx])
                    resData2=float(words2[resNdx])
                    errData1=float(words1[errNdx])
                    errData2=float(words2[errNdx])

                    if op is 'avg':
                        N = mesh1.numHist+mesh2.numHist
                        S1 = resData1*mesh1.numHist
                        S2 = resData2*mesh2.numHist
                        T1 = mesh1.numHist*resData1*resData1*(mesh1.numHist*errData1*errData1+1)
                        T2 = mesh2.numHist*resData2*resData2*(mesh2.numHist*errData2*errData2+1)
                        mean = (S1+S2)/N
                        stddev2=((T1+T2)/N-mean*mean)/N
                        resDataOut = mean
                        if mean ==0:
                            errDataOut=0
                        else:
                            errDataOut = math.sqrt(stddev2)/mean
                    elif op is 'add':
                        resDataOut = resData1+resData2
                        if resDataOut == 0:
                            errDataOut = 0
                        else:
                            errDataOut = math.sqrt((resData1*errData1)**2 + (resData2*errData2)**2)/resDataOut
                    elif op is 'sub':
                        resDataOut = resData1-resData2
                        if resDataOut == 0:
                            errDataOut = 0
                        else:
                            errDataOut = math.sqrt((resData1*errData1)**2 + (resData2*errData2)**2)/resDataOut                        
                    else:
                        print 'Error: unknown operation specified'
                        sys.exit(1)                            
                    
                    if enNdx >=0:
                        file.write('%10s'%(enData1))
                    if xNdx >=0:
                        file.write(' %10.3f'%(xData1))
                    if yNdx >=0:
                        file.write(' %9.3f'%(yData1))
                    if zNdx >=0:
                        file.write(' %9.3f'%(zData1))
                    file.write(' %10.5e'%(resDataOut))
                    file.write(' %10.5e\n'%(errDataOut))

            line1 = mesh1.file.readline()
            mesh2.file.readline()
            line1 = mesh1.file.readline()
            line2 = mesh2.file.readline()
        except Exception,inst:
            print "Error Streaming %s and %s.: %s" % (in1,in2, inst.args)
            sys.exit(1)


    file.close()
    mesh1.file.close()
    mesh2.file.close()

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
    print 'meshtal_combine: A tool for combining MCNP meshtal files\n'
    print 'python meshtal_combine.py [OPTIONS] OPERATION INPUT1 INPUT2 ...\n'
    print 'Operations: either --add or --avg'
    print 'OPTIONS'
    print '-o OUTFILE\tSet Output file name to OUTFILE (default COMBINEDMESH)'
    print '-s\t\tStreaming Mode, for very large files'
    print '-d\t\tDelete input files after processing'
    print '-h\t\tHelp\n'




def main():

    #flags
    outname = CmdLineFind('-o','COMBINEDMESH')
    streaming = CmdLineFindIndex('-s');
    add = CmdLineFindIndex('--add')
    sub = CmdLineFindIndex('--sub')
    avg = CmdLineFindIndex('--avg')
    delete = CmdLineFindIndex('-d');
    showHelp = CmdLineFindIndex('-h')
    
    if showHelp > 0:
        help()
        sys.exit(1)        

    #figure out where input data is (must be after flags)

    filesNdx = 1
    if CmdLineFindIndex('-o') > 0:
        filesNdx += 2
    if streaming > 0:
        filesNdx += 1
    if delete > 0:
        filesNdx+=1
    if add > 0:
        filesNdx+=1
    if sub > 0:
        filesNdx+=1
    if avg > 0:
        filesNdx+=1

    if add*avg*sub <= 0:
        print 'Error: Please choose a single operation.'
        help()
        sys.exit(1)
 
    if len(sys.argv)-filesNdx < 2:
        print 'Error: Not enough files'
        help()
        sys.exit(1)
        
    meshfiles = sys.argv[filesNdx:]
        
    if avg >=0  and len(meshfiles) > 2:
        print 'Error: Averaging only supported for 2 files'
        help()
        sys.exit(1)

    if sub >=0 and len(meshfiles) > 2:
        print 'Error: Subtraction only supported for 2 files'
        help()
        sys.exit(1)
    
    if streaming < 0:
        meshtal = Meshtal()
        meshtal.read(meshfiles[0])
        for ndx in range(1,len(meshfiles)):
            meshtal2=Meshtal()
            meshtal2.read(meshfiles[ndx])
            if add:
                meshtal.Add(meshtal2)
            if sub:
                meshtal.Sub(meshtal2)
            elif avg:
                meshtal.Avg(meshtal2)
        meshtal.Write(outname)
    else:
        outnames = []
        operation = ""
        assert(add*sub*avg >= 0)
        if add >=0: operation = "add"
        if sub >=0: operation = "sub"
        if avg >=0: operation = "avg"
        for ndx in range(2,len(meshfiles)):
            outnames.append(outname+"."+str(ndx))
        outnames.append(outname)
        Stream(meshfiles[0],meshfiles[1],outnames[0],op=operation)
        if delete > 0:
            subprocess.call('rm -rf '+meshfiles[0],shell=True)
            subprocess.call('rm -rf '+meshfiles[1],shell=True)
        for ndx in range(2,len(meshfiles)):
            Stream(outnames[ndx-2],meshfiles[ndx],outnames[ndx-1],op=operation)
            print 'rm -rf '+outnames[ndx-2]
            subprocess.call('rm -rf '+outnames[ndx-2],shell=True)
            if delete > 0:
                subprocess.call('rm -rf '+meshfiles[ndx],shell=True)


if __name__ == "__main__":
    main()
