"""Recupera un bloque de la descarga completa anterior si falla un equipo.

La descarga original concatena los equipos en el orden de teams.get_teams().
Antes de recuperar el bloque faltante se comparan los otros 29 bloques completos.
"""
from pathlib import Path
import pandas as pd
from nba_api.stats.static import teams

def main():
    root = Path(__file__).resolve().parents[1] / 'data' / 'raw'
    original = pd.read_csv(root / 'nba_api_player_stats_2020_21.csv')
    catalog = teams.get_teams()
    paths = {t['id']: root / f"api_2020-21_{t['id']}.csv" for t in catalog}
    available = {k:pd.read_csv(p) for k,p in paths.items() if p.exists()}
    missing = [t for t in catalog if t['id'] not in available]
    assert len(missing)==1, 'Esta recuperación requiere exactamente un equipo faltante'
    missing_count = len(original)-sum(len(f) for f in available.values())
    assert missing_count>0
    position=0
    recovered=None
    cols=['PLAYER_ID','PLAYER_NAME','GP','PTS','AST','REB','PLUS_MINUS']
    for t in catalog:
        count=len(available[t['id']]) if t['id'] in available else missing_count
        block=original.iloc[position:position+count].reset_index(drop=True).copy()
        position+=count
        if t['id'] in available:
            assert block[cols].equals(available[t['id']][cols]), t['abbreviation']
        else:
            block['TEAM_ID']=t['id']
            block['TEAM_ABBREVIATION']=t['abbreviation']
            recovered=block
    assert position==len(original)
    recovered.to_csv(paths[missing[0]['id']],index=False)
    print('Recuperado desde descarga original:',missing[0]['abbreviation'],len(recovered))

if __name__=='__main__':
    main()
