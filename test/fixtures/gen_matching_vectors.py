# Independent reference implementation of brief §6.3 + founder decisions.
# Regenerate: python test/fixtures/gen_matching_vectors.py
import json, math, os
R=6371000.0
def dist(a,b):
    la1,lo1,la2,lo2=map(math.radians,(a[0],a[1],b[0],b[1]))
    h=math.sin((la2-la1)/2)**2+math.cos(la1)*math.cos(la2)*math.sin((lo2-lo1)/2)**2
    return 2*R*math.asin(math.sqrt(h))
L=dict(pickup=1000,detour=10,time=20,dest=1500)
def hm(s): h,m=s.split(':'); return int(h)*60+int(m)
def lin(w,v,lim): return w*min(1,max(0,1-v/lim))
def evaluate(s,g):
    dm=dist(s['work'],g['destinationPoint'])
    if dm>L['dest']: return None
    pm=min(dist(s['home'],p) for p in g['pickupPoints'])
    if pm>L['pickup'] or g['detourMinutes']>L['detour']: return None
    shared=len(set(s['days'])&set(g['days']))
    if shared==0: return None
    ms=g['members']
    if g.get('womenOnly') and not s.get('isWoman'): return None
    if s.get('womenOnly') and any(not m['isWoman'] for m in ms): return None
    if g.get('sameCompanyOnly') and g['sameCompanyOnly']!=s.get('company'): return None
    if g.get('sameCompoundOnly') and g['sameCompoundOnly']!=s.get('compound'): return None
    dd=abs(hm(s['departure'])-hm(g['going'])); rd=abs(hm(s['ret'])-hm(g['ret']))
    legs=[]
    for leg in s['legs']:
        diff=dd if leg=='going' else rd
        cap=(g['freeSeatsGoing'] if leg=='going' else g['freeSeatsReturn'])>0 if s['role']=='rider' else any(m['role']=='rider' and leg in m['legs'] for m in ms)
        if diff<=L['time'] and cap: legs.append(leg)
    if not legs: return None
    comm=10.0 if any((s.get('company') and m.get('company')==s['company']) or (s.get('compound') and m.get('compound')==s['compound']) for m in ms) else 0.0
    ar=sum(m['rating'] for m in ms)/len(ms); rel=sum(m['reliability'] for m in ms)/len(ms)
    f=[lin(25,dm,L['dest']),lin(20,dd,L['time']),lin(15,pm,L['pickup']),lin(10,rd,L['time']),10*shared/len(s['days']),comm,10*((ar/5)+(rel/100))/2]
    same_company = bool(s.get('company')) and any(m.get('company')==s['company'] for m in ms)
    ranked=[(f[0],'destination'),(f[1],'departure'),(f[2],'pickup')]
    if f[5]>0 and f[3]>0: ranked.append((f[5]+f[3],'companyReturn' if same_company else 'compound'))
    else:
        if f[5]>0: ranked.append((f[5],'company' if same_company else 'compound'))
        ranked.append((f[3],'ret'))
    ranked += [(f[4],'days'),(f[6],'rating')]
    pos=[r for r in ranked if r[0]>0]
    order=sorted(range(len(pos)),key=lambda i:(-pos[i][0],i))
    reasons=[pos[i][1] for i in order[:4]]
    return dict(id=g['id'],legs=legs,score=math.floor(sum(f)+0.5),reasons=reasons)
def match(s,gs):
    c=[m for m in (evaluate(s,g) for g in gs) if m]
    full=sorted([m for m in c if set(s['legs'])<=set(m['legs'])],key=lambda m:-m['score'])
    if full: return dict(main=full[0]['id'],mainScore=full[0]['score'],mainReasons=full[0]['reasons'],returnMatch=None,alternatives=[[m['id'],m['score']] for m in full[1:]])
    per={}
    for leg in s['legs']:
        sv=sorted([m for m in c if leg in m['legs']],key=lambda m:-m['score'])
        per[leg]=sv[0] if sv else None
    if any(v is None for v in per.values()): return dict(main=None,mainScore=None,mainReasons=[],returnMatch=None,alternatives=[])
    main=per.get('going') or per['ret']; ret=per.get('ret')
    return dict(main=main['id'],mainScore=main['score'],mainReasons=main['reasons'],returnMatch=ret['id'] if ret and ret is not main else None,alternatives=[])

SZ=[30.0400,30.9800]; SV=[30.0710,31.0170]
def off(p,dlat=0.0,dlng=0.0): return [round(p[0]+dlat,6),round(p[1]+dlng,6)]
def mem(i,role,woman=False,company=None,compound=None,rating=4.8,rel=95,legs=('going','ret')):
    return dict(id=i,firstName=i,initials=i[:2].upper(),role=role,isWoman=woman,company=company,compound=compound,rating=rating,reliability=rel,legs=list(legs))
def grp(i,going='07:25',ret='17:00',pick=0.0027,dest=0.0009,days=('sun','mon','tue','wed','thu'),members=None,fg=2,fr=2,detour=6,**kw):
    g=dict(id=i,origin='sheikhZayed',destination='smartVillage',destinationPoint=off(SV,dest),pickupPoints=[off(SZ,pick)],going=going,ret=ret,days=list(days),
      members=members or [mem('ahmed','driver',rating=4.9,rel=97),mem('mohamed','driver',rating=4.8,rel=96),mem('sara','rider',True,rating=5.0,rel=98)],
      price=40,freeSeatsGoing=fg,freeSeatsReturn=fr,detourMinutes=detour,womenOnly=False,sameCompanyOnly=None,sameCompoundOnly=None)
    g.update(kw); return g
def seeker(**kw):
    s=dict(role='rider',home=SZ,work=SV,departure='07:30',ret='17:00',days=['sun','mon','tue','wed','thu'],legs=['going','ret'],isWoman=False,company=None,compound=None,womenOnly=False,sameCompanyOnly=False,sameCompoundOnly=False)
    s.update(kw); return s
cases=[]
def case(name,s,gs):
    cases.append(dict(name=name,seeker=s,groups=gs,expect=match(s,gs)))
case('rider on the corridor: best group, ranked alternatives, hard-limit exclusions', seeker(), [
  grp('g1'), grp('g2',going='07:40',pick=0.0072,dest=0.0040), grp('g3',going='07:15',ret='17:20',pick=0.0063),
  grp('night',going='10:00',ret='19:00'), grp('far_pickup',pick=0.0110), grp('long_detour',detour=12),
  grp('far_dest',dest=0.0150), grp('weekend',days=('fri','sat')), grp('full',fg=0,fr=0)])
case('departure exactly 20 min passes; 21 min fails', seeker(), [grp('at20',going='07:50'), grp('at21',going='07:51')])
case('going and return matched independently', seeker(), [
  grp('morning_only',ret='19:00'), grp('evening_only',going='09:00',ret='17:05')])
case('one leg with no group means no match', seeker(), [grp('morning_only',ret='19:00')])
case('women-only group excludes men', seeker(), [grp('women',womenOnly=True)])
case('women-only group accepts women', seeker(isWoman=True), [grp('women',womenOnly=True)])
case('seeker women-only preference needs an all-women group', seeker(isWoman=True,womenOnly=True), [
  grp('mixed'), grp('allwomen',members=[mem('mona','driver',True),mem('hana','rider',True)])])
case('same company scores community points', seeker(company='acme'), [
  grp('acme',members=[mem('ahmed','driver',company='acme'),mem('sara','rider',True)]), grp('other')])
case('driver going-only needs riders on the going leg', seeker(role='driver',legs=['going']), [
  grp('ret_riders',members=[mem('ali','driver'),mem('sara','rider',True,legs=('ret',))]),
  grp('going_riders',members=[mem('ali','driver'),mem('sara','rider',True,legs=('going',))])])
json.dump(dict(limits=L,cases=cases),open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'matching_vectors.json'),'w',newline='\n'),indent=1)
for c in cases: print(c['name'][:55].ljust(56), c['expect'])
