"""Pruebas HTTP reales de arranque y rutas, sin dependencias de terceros."""
import argparse
import json
import os
from pathlib import Path
import socket
import subprocess
import time
import urllib.request
import urllib.error
import xml.etree.ElementTree as ET

def request(url):
    try:
        with urllib.request.urlopen(url, timeout=4) as r:
            return r.status, r.read().decode('utf-8')
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode('utf-8')

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--executable',required=True)
    parser.add_argument('--dll')
    parser.add_argument('--cwd',required=True)
    parser.add_argument('--junit',required=True)
    args=parser.parse_args()
    with socket.socket() as sock:
        sock.bind(('127.0.0.1',0));port=sock.getsockname()[1]
    env=os.environ.copy()
    env.update(ASPNETCORE_URLS=f'http://127.0.0.1:{port}',ASPNETCORE_ENVIRONMENT='Production',DOTNET_CLI_TELEMETRY_OPTOUT='1')
    command=[args.executable]+([args.dll] if args.dll else [])
    checks = [('/',200,'PetBoutique'),('/health',200,'Healthy'),('/ruta-inexistente-isy2201',404,None),
              ('/api/catalog',200,None),('/api/catalog/quote?productId=1&quantity=2',200,None),
              ('/api/catalog/quote?productId=1&quantity=0',400,None),
              ('/api/catalog/quote?productId=1&quantity=11',400,None),
              ('/api/catalog/quote?productId=999&quantity=1',404,None),
              ('/api/catalog/quote?productId=1&quantity=abc',400,None)]
    suite=ET.Element('testsuite',name='PetBoutique HTTP',tests=str(len(checks)))
    failures=0
    junit=Path(args.junit);junit.parent.mkdir(parents=True,exist_ok=True)
    with open(junit.with_suffix('.log'),'w',encoding='utf-8') as log:
        process=subprocess.Popen(command,cwd=args.cwd,env=env,stdout=log,stderr=subprocess.STDOUT)
        base=f'http://127.0.0.1:{port}'
        try:
            ready=False
            for _ in range(40):
                if process.poll() is not None:break
                try:
                    if request(base+'/health')[0]==200:ready=True;break
                except (OSError,urllib.error.URLError):pass
                time.sleep(.25)
            for path,status,contains in checks:
                case=ET.SubElement(suite,'testcase',name=path,classname='HTTP')
                try:
                    assert ready,'La aplicación no inició correctamente; revisar .log'
                    actual,body=request(base+path)
                    assert actual==status,f'Esperado {status}; obtenido {actual}'
                    if contains:assert contains in body,f'Falta contenido: {contains}'
                    if path=='/api/catalog':
                        data=json.loads(body)
                        assert len(data)==3 and len({p['id'] for p in data})==3
                        assert all(p['priceClp']>0 for p in data)
                    if path=='/api/catalog/quote?productId=1&quantity=2':
                        data=json.loads(body)
                        assert data['total']==25980 and data['currency']=='CLP' and data['simulation'] is True
                    print(f'PASS {path}: HTTP {actual}')
                except Exception as error:
                    failures+=1;ET.SubElement(case,'failure',message=str(error)).text=str(error)
                    print(f'FAIL {path}: {error}')
        finally:
            if process.poll() is None:
                process.terminate()
                try:process.wait(timeout=10)
                except subprocess.TimeoutExpired:process.kill();process.wait()
            suite.set('failures',str(failures))
            ET.ElementTree(suite).write(junit,encoding='utf-8',xml_declaration=True)
    return bool(failures)

if __name__=='__main__':raise SystemExit(main())
