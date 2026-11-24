"""Render measured VCD signals. Run after make test; requires matplotlib."""
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

REPO = Path(__file__).resolve().parents[1]
IS_MIPS = REPO.name == 'mips-lui-extension'
def read_vcd(path):
    scope=[]; names={}; values={}; time=0; header=True
    for line in path.read_text().splitlines():
        p=line.strip().split()
        if not p: continue
        if header:
            if p[0]=='$scope':scope.append(p[2])
            elif p[0]=='$upscope':scope.pop()
            elif p[0]=='$var':names['.'.join(scope+[p[4]])]=(p[3],int(p[2]));values.setdefault(p[3],[])
            elif p[0]=='$enddefinitions':header=False
            continue
        if p[0].startswith('#'):time=int(p[0][1:])/1000.0
        elif p[0].startswith(('b','B')) and len(p)==2:
            raw=p[0][1:]; values[p[1]].append((time,None if any(c in raw.lower() for c in 'xz') else int(raw,2)))
        elif p[0][0] in '01xz':
            values[p[0][1:]].append((time,None if p[0][0] in 'xz' else int(p[0][0])))
    return names,values

if IS_MIPS:
    path=REPO/'build/mips.vcd';lo,hi=10,90
    specs=[('clk','tb_mips.clk'),('reset_n','tb_mips.reset_n'),('PC','tb_mips.pc'),
           ('instruction','tb_mips.instruction'),('ALU control','tb_mips.dut.core.alu_control'),
           ('ALU result','tb_mips.alu_out'),('reg_write','tb_mips.reg_write'),
           ('write register','tb_mips.dut.core.write_reg'),('write-back','tb_mips.dut.core.result')]
    title='MIPS | Load Upper Immediate'; subtitle='0x3C08AAAA  ->  $t0 = 0xAAAA0000'
else:
    path=REPO/'build/system.vcd';lo,hi=160,720
    specs=[('clk','tb_system.clk'),('TX address','tb_system.ta'),
           ('FIFO write','tb_system.buffered.inc_adrs_tx'),('FIFO empty','tb_system.empty'),
           ('FIFO output','tb_system.fifo_data'),('RAM write','tb_system.buffered.wr_mem'),
           ('RX address','tb_system.ra'),('RAM[3]','tb_system.b3'),('RX finished','tb_system.rf1')]
    title='BitFlow | FIFO data transfer';subtitle='ROM -> 4 x 8 FIFO -> RAM  |  B2  CA  F0  0F'
names,values=read_vcd(path)
fig,ax=plt.subplots(figsize=(12,6.75),dpi=160)
fig.patch.set_facecolor('#102032');ax.set_facecolor('#102032')
colors=['#68d1df','#b8c6d6','#7ce0ac','#8fb6ff','#f4ce77','#68d1df','#b8c6d6','#7ce0ac','#8fb6ff']
for i,(label,name) in enumerate(specs):
    code,width=names[name]; seq=values[code];events={}
    for t,v in seq:events[t]=v
    before=[t for t in events if t<=lo];v=events[max(before)] if before else None
    points=[(lo,v)]+[(t,v) for t,v in sorted(events.items()) if lo<t<hi]+[(hi,None)]
    y=len(specs)-i
    for k in range(len(points)-1):
        t,v=points[k];end=points[k+1][0]
        if width==1:
            level=y+(0.28 if v==1 else -0.28)
            ax.plot([t,end],[level,level],color=colors[i],lw=1.6,alpha=1 if v is not None else .35)
            if k and points[k-1][1]!=v:ax.plot([t,t],[y-.28,y+.28],color=colors[i],lw=1)
        else:
            ax.plot([t,end],[y,y],color=colors[i],lw=1.5)
            if k:ax.plot([t,t],[y-.16,y+.16],color=colors[i],lw=1)
            if end-t>(hi-lo)*.035:
                txt='X' if v is None else (f'{v:0{(width+3)//4}X}' if width>4 else str(v))
                ax.text((t+end)/2,y+.13,txt,color=colors[i],fontsize=9,ha='center',family='monospace')
ax.set_yticks(range(len(specs),0,-1),[a for a,_ in specs],color='#e5edf5',fontsize=10)
ax.tick_params(axis='y',length=0,pad=12)
ax.tick_params(axis='x',colors='#c3d0df',labelsize=9)
ax.set_xlim(lo,hi);ax.set_ylim(.35,len(specs)+.7)
ax.grid(axis='x',color='#526377',alpha=.3,lw=.6)
for spine in ax.spines.values():spine.set_visible(False)
ax.set_xlabel('Simulation time (ns)',color='#c3d0df',labelpad=10)
fig.text(.04,.94,title,color='white',fontsize=23,weight='bold')
fig.text(.04,.885,subtitle,color='#7ce0ac',fontsize=13)
fig.text(.04,.03,'Measured simulation signals | Icarus Verilog | Included self-checking test suite',color='#aabacd',fontsize=9)
fig.subplots_adjust(left=.18,right=.97,bottom=.13,top=.82)
output=REPO/'assets/verification.png';fig.savefig(output,facecolor=fig.get_facecolor());print(output)
