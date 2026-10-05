import json, time, urllib.request, urllib.error, sys
base=sys.argv[1] if len(sys.argv)>1 else 'http://127.0.0.1:8080'
cases=[('/',200,'PetBoutique'),('/health',200,'Healthy'),('/health-web',200,'Healthy'),('/missing',404,None),('/api/catalog',200,None),('/api/catalog/quote?productId=1&quantity=2',200,None),('/api/catalog/quote?productId=1&quantity=0',400,None),('/api/catalog/quote?productId=1&quantity=11',400,None),('/api/catalog/quote?productId=999&quantity=1',404,None),('/api/catalog/quote?productId=1&quantity=x',400,None)]
results=[]
for path,status,expected in cases:
    start=time.perf_counter()
    try:
        with urllib.request.urlopen(base+path,timeout=15) as r: code=r.status; body=r.read().decode()
    except urllib.error.HTTPError as e: code=e.code;body=e.read().decode()
    ok=code==status and (expected is None or expected in body)
    if path=='/api/catalog':
        data=json.loads(body);ok=ok and len(data)==3 and len({p['id'] for p in data})==3 and all(p['priceClp']>0 for p in data)
    if path.endswith('productId=1&quantity=2'):ok=ok and json.loads(body)['total']==25980
    results.append({'path':path,'expected':status,'actual':code,'passed':ok,'seconds':round(time.perf_counter()-start,3)})
report={'base':base,'utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'passed':sum(r['passed'] for r in results),'total':len(results),'results':results}
print(json.dumps(report,indent=2))
sys.exit(0 if all(r['passed'] for r in results) else 1)
