#!/usr/bin/env python3
import argparse, datetime, json, pathlib, subprocess, time, urllib.request

parser=argparse.ArgumentParser()
parser.add_argument('--base',default='http://127.0.0.1')
parser.add_argument('--output',default='/var/log/petboutique-s8/health.jsonl')
args=parser.parse_args(); checks=[]
for endpoint in ['/health-web','/health','/api/catalog']:
    start=time.perf_counter()
    try:
        with urllib.request.urlopen(args.base+endpoint,timeout=5) as r:
            body=r.read().decode(); status=r.status
        valid=status==200 and (('Healthy' in body) if 'health' in endpoint else len(json.loads(body))==3)
        item={'path':endpoint,'status':status,'ok':valid}
    except Exception as e: item={'path':endpoint,'ok':False,'error':str(e)}
    item['milliseconds']=round((time.perf_counter()-start)*1000,2); checks.append(item)
def command(argv):
    r=subprocess.run(argv,text=True,capture_output=True,timeout=10)
    return {'exit':r.returncode,'output':r.stdout.strip(),'error':r.stderr.strip()}
record={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'checks':checks,
        'containers':command(['docker','ps','--filter','label=com.docker.compose.project=petboutique-s6','--format','{{.Names}} {{.Status}}']),
        'resources':command(['docker','stats','--no-stream','--format','{{.Name}} {{.CPUPerc}} {{.MemUsage}}']),
        'disk':command(['df','-P','/'])}
record['ok']=all(c['ok'] for c in checks) and record['containers']['exit']==0 and record['resources']['exit']==0
text=json.dumps(record,ensure_ascii=False)
path=pathlib.Path(args.output);path.parent.mkdir(parents=True,exist_ok=True)
with path.open('a',encoding='utf8') as f:f.write(text+'\n')
print(text)
if not record['ok']:
    subprocess.run(['logger','-p','daemon.err','-t','petboutique-s8','ALERTA: fallo en salud o recoleccion de metricas'],check=False)
    raise SystemExit(1)
