"""Render the measured Original/Delayed3 comparison as PNG and PDF."""
import csv
from pathlib import Path

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib import font_manager
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'results/author_vs_latest_r'
font_path = Path('C:/Windows/Fonts/msjh.ttc')
if font_path.exists():
    font_manager.fontManager.addfont(str(font_path))
    plt.rcParams['font.family'] = font_manager.FontProperties(fname=str(font_path)).get_name()
plt.rcParams.update({'axes.unicode_minus': False, 'font.size': 11,
                     'axes.spines.top': False, 'axes.spines.right': False,
                     'figure.facecolor': '#f5f7fb', 'axes.facecolor': '#ffffff'})

def read(name):
    with (OUT / name).open(encoding='utf-8-sig') as f:
        return list(csv.DictReader(f))

rows = {r['pipeline']: r for r in read('summary.csv')}
old, new = rows['Original'], rows['Delayed3']
colors = ['#8896aa', '#087f8c']
fig = plt.figure(figsize=(14, 11))
grid = fig.add_gridspec(2, 2, height_ratios=[1, 1.45], hspace=.48, wspace=.23)
ax1 = fig.add_subplot(grid[0, 0])
ax2 = fig.add_subplot(grid[0, 1])
ax3 = fig.add_subplot(grid[1, :])
fig.suptitle('原方法與 Delayed3 改良方法比較', x=.08, ha='left', y=.98,
             fontsize=23, fontweight='bold', color='#172b4d')
fig.text(.08, .935, '相同 42 組資料｜作者公開 R 程式實測｜主要結果依標註選取最佳層級',
         fontsize=12, color='#53657d')

keys = ['F1_mean', 'F1_biased_mean', 'covering_mean']
x = np.arange(3)
for offset, row, color, label in [(-.19, old, colors[0], '原方法'), (.19, new, colors[1], 'Delayed3')]:
    values = [float(row[k]) for k in keys]
    bars = ax1.bar(x + offset, values, width=.36, color=color, label=label)
    ax1.bar_label(bars, fmt='%.4f', padding=4, fontsize=10)
ax1.set_xticks(x, ['平均 F1', 'F1-biased', 'Covering'])
ax1.set_ylim(0, 1.04)
ax1.set_ylabel('分數（越高越好）')
ax1.set_title('整體品質：平均 F1 增加 0.0357', loc='left', fontweight='bold', pad=15)
ax1.legend(loc='upper left', frameon=False, ncol=2)
ax1.grid(axis='y', alpha=.15)
ax1.set_axisbelow(True)

for offset, row, color in [(-.19, old, colors[0]), (.19, new, colors[1])]:
    bars = ax2.bar(x + offset, [int(row[k]) for k in ['TP_total', 'FP_total', 'FN_total']],
                   width=.36, color=color)
    ax2.bar_label(bars, padding=4)
ax2.set_xticks(x, ['正確 TP ↑', '誤報 FP ↓', '漏報 FN ↓'])
ax2.set_ylim(0, 110)
ax2.set_ylabel('全部資料合計切點數')
ax2.set_title('多找出 5 個切點，誤報總數維持相同', loc='left', fontweight='bold', pad=15)
ax2.grid(axis='y', alpha=.15)
ax2.set_axisbelow(True)

paired = read('paired_by_dataset.csv')
changed = sorted([r for r in paired if abs(float(r['delta'])) > 1e-10],
                 key=lambda r: float(r['delta']))
y = np.arange(len(changed))
deltas = [float(r['delta']) for r in changed]
bars = ax3.barh(y, deltas, color=[colors[1] if d > 0 else '#d36a55' for d in deltas], height=.65)
ax3.set_yticks(y, [r['dataset'] for r in changed])
ax3.axvline(0, color='#53657d', linewidth=1)
ax3.set_xlim(min(deltas) - .16, max(deltas) + .13)
for bar, value in zip(bars, deltas):
    ax3.text(value + (.012 if value > 0 else -.012), bar.get_y()+bar.get_height()/2,
             f'{value:+.4f}', ha='left' if value > 0 else 'right', va='center', fontsize=10)
ax3.set_xlabel('F1 差值（Delayed3 - 原方法）')
ax3.set_title('逐資料集差異：7 組提升、29 組持平、6 組下降（圖中列出有變化的 13 組）',
              loc='left', fontweight='bold', pad=15)
ax3.grid(axis='x', alpha=.15)
ax3.set_axisbelow(True)
fig.text(.08, .043, '解讀限制：F1 平均差的來源群 bootstrap 95% 區間為 [-0.0069, 0.0805]，包含 0；尚不能宣稱穩定顯著勝出。',
         fontsize=10, color='#53657d')
fig.text(.08, .022, 'F1-biased 與 Covering 使用相同的 F1 選層預測；29 組持平資料未在下圖逐列顯示。',
         fontsize=10, color='#53657d')
fig.subplots_adjust(left=.16, right=.96, top=.86, bottom=.12)
for extension in ['png', 'pdf']:
    target = OUT / f'comparison_chart.{extension}'
    fig.savefig(target, dpi=180, facecolor=fig.get_facecolor())
    print(target)
