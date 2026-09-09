"""Exporta el esquema real y dibuja el ER. Uso: python src/build_er.py --env .env

Sin --env usa docs/diagrams/schema_snapshot.json para regenerar el PDF sin conexión.
"""
import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs' / 'diagrams'
PDF = ROOT / 'output' / 'pdf' / 'modelo_er_final.pdf'


def snapshot(env):
    import psycopg
    from dotenv import dotenv_values
    config = dotenv_values(env)
    tables = {}
    with psycopg.connect(host=config.get('DB_HOST','localhost'),
                         port=config.get('DB_PORT','5432'),
                         dbname=config.get('DB_NAME','nba_project'),
                         user=config.get('DB_USER','postgres'),
                         password=config.get('DB_PASSWORD')) as db:
        db.read_only = True
        rows = db.execute('''SELECT c.relname,a.attname,format_type(a.atttypid,a.atttypmod),
            a.attnotnull,pg_get_expr(d.adbin,d.adrelid),a.attidentity
            FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
            JOIN pg_attribute a ON a.attrelid=c.oid
            LEFT JOIN pg_attrdef d ON d.adrelid=c.oid AND d.adnum=a.attnum
            WHERE n.nspname='public' AND c.relkind='r' AND a.attnum>0 AND NOT a.attisdropped
            ORDER BY c.relname,a.attnum''').fetchall()
        for table,name,kind,nn,default,identity in rows:
            tables.setdefault(table,{'columns':[], 'constraints':[]})['columns'].append(
                dict(name=name,type=kind,not_null=nn,default=default,identity=identity))
        for table,kind,definition in db.execute('''SELECT c.relname,co.contype,pg_get_constraintdef(co.oid)
            FROM pg_constraint co JOIN pg_class c ON c.oid=co.conrelid
            WHERE co.connamespace='public'::regnamespace AND co.contype IN ('p','f','u','c')
            ORDER BY c.relname,co.contype,co.conname''').fetchall():
            tables[table]['constraints'].append(dict(kind=kind,definition=definition))
    # El PDF no se publica si las columnas/PK del SQL no coinciden con la base.
    sql=(ROOT/'database/schema.sql').read_text(encoding='utf-8')
    blocks=re.findall(r'CREATE TABLE IF NOT EXISTS (\w+)\s*\((.*?)\n\);',sql,re.S)
    assert set(tables)=={t for t,b in blocks}, 'Tablas diferentes entre SQL y PostgreSQL'
    for table,block in blocks:
        declared=[]
        for line in block.splitlines():
            match=re.match(r'\s*(\w+)\s+(BIGINT|TEXT|VARCHAR|SMALLINT|DATE|BOOLEAN|NUMERIC|CHAR|INTEGER|TIMESTAMP)\b',line)
            if match: declared.append(match.group(1))
        assert declared==[x['name'] for x in tables[table]['columns']], table
        pk=re.search(r'PRIMARY KEY\s*\(([^)]+)\)',block)
        if pk: expected=[x.strip() for x in pk.group(1).split(',')]
        else: expected=[line.strip().split()[0] for line in block.splitlines() if 'PRIMARY KEY' in line]
        actual=next(c['definition'] for c in tables[table]['constraints'] if c['kind']=='p')
        assert actual=='PRIMARY KEY ('+', '.join(expected)+')', table
    assert sum(c['kind']=='f' for t in tables.values() for c in t['constraints'])==3
    return dict(verified='2026-09-08',schema_sha256=hashlib.sha256(sql.encode()).hexdigest(),tables=tables)


def render(data):
    from reportlab.pdfgen import canvas
    from reportlab.lib.pagesizes import A3, landscape
    from reportlab.lib.colors import HexColor, Color
    from reportlab.pdfbase import pdfmetrics
    PDF.parent.mkdir(parents=True,exist_ok=True)
    width,height=landscape(A3)
    c=canvas.Canvas(str(PDF),pagesize=(width,height))
    c.setTitle('Proyecto NBA - Modelo entidad-relación final')
    navy='#15354B'; teal='#187D80'; gray='#526675'; pale='#EAF1F4'
    def text(x,y,value,size=10,font='Helvetica',color=navy):
        c.setFillColor(HexColor(color));c.setFont(font,size);c.drawString(x,height-y,value)
    def line(x1,y1,x2,y2,color=teal,dash=False):
        c.setStrokeColor(HexColor(color));c.setLineWidth(1.4);c.setDash(5,3) if dash else c.setDash()
        c.line(x1,height-y1,x2,height-y2);c.setDash()
    def head(number,title,subtitle):
        c.setFillColor(HexColor(navy));c.rect(0,height-8,width,8,fill=1,stroke=0)
        text(38,40,'BD NBA  /  DOCUMENTACIÓN TÉCNICA',10,'Helvetica-Bold',teal)
        text(38,72,title,25,'Helvetica-Bold')
        text(38,94,subtitle,10)
        text(width-150,height-23,f'08 SEP 2026   /   {number} de 2',9,color=gray)
    boxes={}
    def table(name,x,y):
        spec=data['tables'][name]; rows=spec['columns']; w=260;h=51+len(rows)*13
        boxes[name]=(x,y,w,h)
        c.setFillColor(HexColor('#FFFFFF'));c.setStrokeColor(HexColor('#BACAD3'))
        c.roundRect(x,height-y-h,w,h,5,fill=1,stroke=1)
        c.setFillColor(HexColor(navy));c.roundRect(x,height-y-29,w,29,5,fill=1,stroke=0)
        text(x+10,y+19,name,12,'Helvetica-Bold','#FFFFFF')
        text(x+8,y+42,'LLAVE',6.6,'Helvetica-Bold',gray)
        text(x+49,y+42,'COLUMNA',6.6,'Helvetica-Bold',gray)
        text(x+187,y+42,'TIPO',6.6,'Helvetica-Bold',gray)
        pk=[];fk=[]
        for co in spec['constraints']:
            if co['kind'] in ['p','f']:
                keys=re.search(r'\(([^)]+)\)',co['definition']).group(1).split(', ')
                (pk if co['kind']=='p' else fk).extend(keys)
        for i,col in enumerate(rows):
            yy=y+56+i*13
            if i%2==0:
                c.setFillColor(HexColor('#F2F6F8'));c.rect(x+1,height-yy-3,w-2,13,fill=1,stroke=0)
            mark='/'.join(k for k,a in [('PK',pk),('FK',fk)] if col['name'] in a)
            name=col['name']+(' *' if col['not_null'] else '')
            kind=col['type'].replace('character varying','varchar').replace('character','char').replace('timestamp without time zone','timestamp')
            text(x+8,yy,mark,7,'Helvetica-Bold',teal)
            text(x+49,yy,name,7.8,'Helvetica-Bold' if mark else 'Helvetica')
            text(x+187,yy,kind,7.1,color=gray)
            assert pdfmetrics.stringWidth(name,'Helvetica-Bold' if mark else 'Helvetica',7.8)<137,name
            assert pdfmetrics.stringWidth(kind,'Helvetica',7.1)<70,kind
        return h
    head(1,'Modelo físico de la base de datos','10 tablas · Todas las columnas · Tipos y llaves verificados contra PostgreSQL y schema.sql')
    for name,x,y in [('player',38,126),('player_attribute',38,340),
                     ('team',322,126),('team_salary',322,340),
                     ('game',606,126),('game_official',606,425),('official',606,585),
                     ('draft_pick',890,126),('player_salary',890,340),('player_season_stat',890,554)]:
        table(name,x,y)
    def relation(parent,child,label,card,reverse=False):
        px,py,pw,ph=boxes[parent];cx,cy,cw,ch=boxes[child]
        xx=px+pw/2
        a=py+ph if not reverse else py
        b=cy if not reverse else cy+ch
        line(xx,a,xx,b)
        text(xx+8,a+(12 if not reverse else -6),'1',9,'Helvetica-Bold',teal)
        text(xx+8,b+(-8 if not reverse else 14),card,9,'Helvetica-Bold',teal)
        text(xx+8,(a+b)/2+3,label,8,color=gray)
    relation('player','player_attribute','player_id','0..1')
    relation('game','game_official','game_id / CASCADE','0..N')
    relation('official','game_official','official_id','0..N',True)
    line(38,778,width-38,778,color='#BACAD3')
    text(38,796,'PK: llave primaria   |   FK: llave foránea real   |   *: NOT NULL (incluye las PK)',9,'Helvetica-Bold')
    text(38,813,'Las tablas sin líneas no tienen FK en el esquema. Sus enlaces lógicos y restricciones adicionales se explican en la página 2.',9,color=gray)
    c.showPage()
    head(2,'Relaciones lógicas y reglas del modelo','Estos enlaces describen el análisis; no son restricciones FOREIGN KEY de PostgreSQL.')
    text(38,130,'PADRE / CATÁLOGO',9,'Helvetica-Bold',teal)
    text(210,130,'TABLA QUE LO REFERENCIA',9,'Helvetica-Bold',teal)
    text(459,130,'ENLACE PROPUESTO',9,'Helvetica-Bold',teal)
    text(757,130,'CARDINALIDAD ESPERADA Y LÍMITE',9,'Helvetica-Bold',teal)
    relations=[
      ('team','game','team_id = home_team_id','1 a 0..N como local; históricos sin catálogo'),
      ('team','game','team_id = away_team_id','1 a 0..N como visitante; sin FK'),
      ('team','player_attribute','team_id = current_team_id','1 a 0..N; equipo de la captura, no historial'),
      ('team','draft_pick','team_id = team_id','1 a 0..N; selecciones históricas'),
      ('player','draft_pick','player_id = player_id','1 a 0..N; no hay UNIQUE sobre player_id'),
      ('team','player_season_stat','team_id = team_id','1 a 0..N; varias temporadas y jugadores'),
      ('player','player_season_stat','player_id = player_id','1 a 0..N; el API puede agregar jugadores'),
      ('team','team_salary','lower(full_name) = lower(team_name)','0..1 nómina por equipo, si el nombre coincide'),
      ('team','player_salary','lower(full_name) = lower(team_name)','1 a 0..N; nombre sin FK'),
      ('player','player_salary','full_name ~ player_name (por resolver)','1 a 0..N esperado; no usar sin validar nombres'),
    ]
    for i,(parent,child,key,note) in enumerate(relations):
        y=151+i*36
        if i%2==0:
            c.setFillColor(HexColor('#F2F6F8'));c.rect(38,height-y-21,width-76,36,fill=1,stroke=0)
        text(48,y+3,parent,10,'Helvetica-Bold')
        line(155,y,191,y,dash=True)
        text(210,y+3,child,10)
        text(459,y+3,key,9)
        text(757,y+3,note,9)
    text(38,534,'Cómo leer las cardinalidades',13,'Helvetica-Bold')
    text(38,555,'1 = exactamente uno; 0..1 = opcional y único; 0..N = cero o varios. En esta página son expectativas del modelo, no garantías del motor.',10)
    text(38,573,'Un registro histórico puede no encontrar padre en los catálogos actuales. Los nombres y abreviaturas tampoco garantizan identidad.',10)
    text(38,608,'Restricciones que sí existen',13,'Helvetica-Bold')
    rules=[
      'draft_pick: PK (draft_year, overall_pick, player_name). El nombre evita sobrescribir selecciones históricas con número 0.',
      'game_official: PK (game_id, official_id). Borrar un partido elimina sus vínculos con árbitros (ON DELETE CASCADE).',
      'player_season_stat: PK (player_id, season, team_id). Permite separar periodos de un jugador traspasado.',
      'player_salary: salary_id es IDENTITY; UNIQUE (season, team_name, player_name, contract_detail, salary_value).',
      'game: CHECK (home_team_id <> away_team_id). Las otras dos FK usan NO ACTION al borrar.',
    ]
    for i,r in enumerate(rules):text(38,633+i*21,r,10)
    text(38,754,'Vistas auxiliares: v_team_seasons, v_team_talent, v_investment_metrics y v_investment_ranking. No son tablas adicionales.',10,color=gray)
    text(38,782,'Fuente: database/schema.sql + catálogo de restricciones de nba_project. El ER.docx anterior queda como referencia histórica.',9,color=gray)
    c.save()
    import pypdfium2 as pdfium
    pdf=pdfium.PdfDocument(str(PDF))
    for i in range(len(pdf)):
        page=pdf[i];bitmap=page.render(scale=2)
        bitmap.to_pil().save(OUT/('modelo_er_final.png' if i==0 else 'relaciones_logicas.png'))
        bitmap.close();page.close()
    pdf.close()
    print(PDF)


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--env');args=parser.parse_args()
    OUT.mkdir(parents=True,exist_ok=True)
    path=OUT/'schema_snapshot.json'
    data=snapshot(args.env) if args.env else json.loads(path.read_text(encoding='utf-8'))
    if args.env:path.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
    render(data)


if __name__=='__main__':
    main()
