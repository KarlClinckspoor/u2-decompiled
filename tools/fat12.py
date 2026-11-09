# minimal FAT12 floppy image extractor: fat12.py IMG OUTDIR
import sys,os,struct
img=open(sys.argv[1],'rb').read(); out=sys.argv[2]; os.makedirs(out,exist_ok=True)
bps,spc,res,nfat,nroot,tot,media,spf=struct.unpack('<HBHBHHBH',img[11:24])
if bps not in (512,) or nfat not in (1,2) or spf==0:
    # pre-BPB disks: guess from size
    sz=len(img); geo={163840:(1,1,64,1,0xfe),184320:(1,2,64,2,0xfc),327680:(2,1,112,1,0xff),368640:(2,1,112,2,0xfd)}
    spc,res,nroot,spf,media=geo[sz][0],1,geo[sz][2],geo[sz][3],geo[sz][4]; bps=512;nfat=2
fat=img[res*bps:(res+spf)*bps]
rootoff=(res+nfat*spf)*bps; dataoff=rootoff+nroot*32
def nxt(c):
    o=c*3//2; v=fat[o]|fat[o+1]<<8
    return (v>>4) if c&1 else (v&0xfff)
def chain(c):
    while 2<=c<0xff0: yield c; c=nxt(c)
def read(c,size=None):
    b=b''.join(img[dataoff+(x-2)*spc*bps:dataoff+(x-1)*spc*bps] for x in chain(c))
    return b[:size] if size is not None else b
def walk(ents,path):
    for i in range(0,len(ents),32):
        e=ents[i:i+32]
        if e[0]==0: break
        if e[0]==0xe5 or e[11]==0x0f or e[11]&8: continue
        name=e[:8].decode('latin1').rstrip(); ext=e[8:11].decode('latin1').rstrip()
        fn=name+('.'+ext if ext else '')
        if fn in('.','..'): continue
        cl,sz=struct.unpack('<HI',e[26:32]); t,d=struct.unpack('<HH',e[22:26])
        p=os.path.join(path,fn)
        if e[11]&0x10: os.makedirs(p,exist_ok=True); walk(read(cl),p)
        else:
            open(p,'wb').write(read(cl,sz) if sz else b'')
            print('%-40s %7d %04d-%02d-%02d %02d:%02d'%(os.path.relpath(p,out),sz,1980+(d>>9),(d>>5)&15,d&31,t>>11,(t>>5)&63))
walk(img[rootoff:dataoff],out)
