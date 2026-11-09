"""Check current R code, latest outputs, and unchanged upstream sources."""
import csv
import hashlib
import json
from pathlib import Path


def main():
    root=Path('results/latest_r')
    original=json.loads(Path('results/upstream_r/source_before.json').read_text(encoding='utf-8'))
    upstream=Path('upstream/scoth-segmentation')
    changed=[p for p,h in original['tracked_sha256'].items()
             if hashlib.sha256((upstream/p).read_bytes()).hexdigest()!=h]
    paths=['r_extension/refined_costs.R','r_extension/impulse_linear_cost.R',
           'r_extension/score_refinements.R','r_extension/delayed_thresholds.R',
           'r_extension/cached_cost.R','experiments/run_latest_r.R']
    config=json.loads((root/'configuration.json').read_text(encoding='utf-8'))
    matches=[hashlib.md5(Path(p).read_bytes()).hexdigest()==h for p,h in zip(paths,config['md5'])]
    with (root/'best_by_dataset.csv').open(encoding='utf-8-sig') as f: rows=list(csv.DictReader(f))
    assert not changed and all(matches) and len(rows)==42
    assert len({r['dataset'] for r in rows})==42 and {r['method'] for r in rows}=={'Delayed3'}
    result=dict(method='Delayed3',datasets=42,upstream_changed=changed,code_matches_configuration=all(matches),
                source_sha256={p:hashlib.sha256(Path(p).read_bytes()).hexdigest() for p in paths})
    (root/'audit.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print('Latest-only R audit passed.')


if __name__=='__main__': main()
