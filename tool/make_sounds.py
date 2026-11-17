import numpy as np, wave, sys, os
SR = 22050
out = sys.argv[1]

def t(d): return np.arange(int(SR*d))/SR
def env(n, a=0.004, r=0.0, decay=None):
    e = np.ones(n)
    na = max(1,int(SR*a)); e[:na] = np.linspace(0,1,na)
    if decay: e *= np.exp(-np.arange(n)/SR*decay)
    if r:
        nr=int(SR*r); e[-nr:] *= np.linspace(1,0,nr)
    return e
def place(buf, sig, at):
    i=int(SR*at); j=min(len(buf), i+len(sig)); buf[i:j]+=sig[:j-i]
def bell(f, d, amp=1.0, decay=5.0):
    x=t(d); s=np.zeros_like(x)
    for r,a,dm in [(1,1,1),(2.0,0.5,1.4),(2.76,0.35,2.0),(5.4,0.15,3.0),(8.93,0.08,4.0)]:
        s+=a*np.sin(2*np.pi*f*r*x)*np.exp(-x*decay*dm)
    return amp*s*env(len(x),0.002)
def mallet(f, d, amp=1.0, decay=7.0):
    x=t(d); s=np.sin(2*np.pi*f*x)+0.35*np.sin(2*np.pi*f*4*x)*np.exp(-x*30)+0.15*np.sin(2*np.pi*f*2*x)
    return amp*s*np.exp(-x*decay)*env(len(x),0.002)
def soft(f, d, amp=1.0, a=0.12, r=0.3, vib=0.0):
    x=t(d); ph=2*np.pi*f*x+(vib*np.sin(2*np.pi*5*x) if vib else 0)
    s=np.sin(ph)+0.3*np.sin(2*ph)+0.1*np.sin(3*ph)
    return amp*s*env(len(x),a,r)
def blip(f, d, amp=1.0):
    x=t(d); s=np.sign(np.sin(2*np.pi*f*x))*0.5+np.sin(2*np.pi*f*x)
    s=np.convolve(s,np.ones(12)/12,mode='same')
    return amp*s*env(len(x),0.003,0.03)
def save(name, sig, peak=0.85):
    sig=np.asarray(sig); m=np.max(np.abs(sig)); sig=sig/m*peak if m>0 else sig
    # tiny fade at the very ends so loops do not click
    n=int(SR*0.004); sig[:n]*=np.linspace(0,1,n); sig[-n:]*=np.linspace(1,0,n)
    pcm=(sig*32767).astype('<i2')
    with wave.open(os.path.join(out,name),'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
    print(name, len(pcm)/SR, 's', os.path.getsize(os.path.join(out,name))//1024,'KB')

N={'C5':523.25,'D5':587.33,'E5':659.25,'G5':783.99,'A5':880.0,'B5':987.77,'C6':1046.5,'E6':1318.5,'G4':392.0,'E4':329.63,'C4':261.63,'A4':440.0,'D6':1174.7,'G6':1568.0}

# ---------------- ringtones (about 3 seconds, loop cleanly, end in a short pause)
b=np.zeros(int(SR*3.0))
for k,(n,at) in enumerate([('C5',0),('E5',.16),('G5',.32),('C6',.48),('G5',.7),('E5',.86),('G5',1.02),('C6',1.18),('E6',1.34)]):
    place(b, mallet(N[n],0.9,0.8), at)
for k,(n,at) in enumerate([('C5',1.5)]): pass
save('ring_marimba.wav', b)

b=np.zeros(int(SR*3.2))
for rep in range(2):
    base=rep*1.5
    place(b, bell(N['B5'],1.3,1.0,3.2), base)
    place(b, bell(N['G5'],1.3,0.9,3.2), base+0.42)
save('ring_bell.wav', b)

b=np.zeros(int(SR*2.6))
for rep in range(2):
    base=rep*1.2
    for k in range(2):
        place(b, blip(N['A5'] if k==0 else N['E6'],0.12,0.9), base+k*0.16)
    for k in range(2):
        place(b, blip(N['A5'] if k==0 else N['E6'],0.12,0.9), base+0.45+k*0.16)
save('ring_pulse.wav', b)

b=np.zeros(int(SR*4.0))
place(b, soft(N['E5'],1.3,0.8,0.15,0.5,3), 0)
place(b, soft(N['G5'],1.3,0.8,0.15,0.5,3), 0.55)
place(b, soft(N['C6'],1.6,0.9,0.15,0.6,3), 1.1)
place(b, soft(N['G5'],1.0,0.4,0.15,0.5,3), 1.1)
save('ring_gentle.wav', b)

b=np.zeros(int(SR*3.0))
for i,n in enumerate(['G5','C6','E6','G6']): place(b, bell(N[n],1.0,0.8,6), i*0.13)
for i,n in enumerate(['G5','C6','E6','G6']): place(b, bell(N[n],1.0,0.8,6), 1.4+i*0.13)
save('ring_sparkle.wav', b)

# ---------------- notification sounds (short)
save('notif_ping.wav', bell(1568,1.0,1.0,7))
x=t(0.55); f=1500*np.exp(-x*6)+500
save('notif_droplet.wav', np.sin(2*np.pi*np.cumsum(f)/SR)*np.exp(-x*9)*env(len(x),0.002))
b=np.zeros(int(SR*1.3)); place(b,bell(N['G5'],1.0,0.8,5),0); place(b,bell(N['C6'],1.0,1.0,5),0.18)
save('notif_chime.wav', b)
x=t(0.22); rng=np.random.default_rng(3)
pop=(np.sin(2*np.pi*(320*np.exp(-x*18)+140)*x)*np.exp(-x*22)+0.25*rng.standard_normal(len(x))*np.exp(-x*90))
save('notif_pop.wav', pop*env(len(x),0.001))
b=np.zeros(int(SR*0.7))
for at in (0,0.17):
    x=t(0.16); place(b, (np.sin(2*np.pi*190*x)+0.5*np.sin(2*np.pi*380*x)+0.2*np.sin(2*np.pi*570*x))*np.exp(-x*32), at)
save('notif_knock.wav', b)
b=np.zeros(int(SR*0.9)); place(b,mallet(N['E5'],0.5,0.8,8),0); place(b,mallet(N['A5'],0.6,0.9,8),0.11)
save('notif_marimba.wav', b)
