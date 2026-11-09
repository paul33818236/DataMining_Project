"""Render comprehensive comparison tables from saved R outputs."""
import csv
from pathlib import Path


def read(path):
    with path.open(encoding='utf-8-sig') as f: return list(csv.DictReader(f))


def table(headers, rows):
    return '\n'.join(['| '+' | '.join(headers)+' |','| '+' | '.join(['---']*len(headers))+' |']+
                     ['| '+' | '.join(map(str,row))+' |' for row in rows])


def main():
    root=Path('results/author_vs_latest_r')
    scores={r['pipeline']:r for r in read(root/'summary.csv')}
    a,b=scores['Original'],scores['Delayed3']
    f=lambda x:f'{float(x):.4f}'
    parts=['# 作者原始 R 與最新 Delayed3 比較表',
           '本表為實驗執行紀錄；原方法與新方法使用相同 42 個資料集、代表標註及正負 5 樣本配對容忍範圍。']
    parts+=['## 方法差異',table(['項目','作者原方法','最新 Delayed3'],[
      ['來源','作者 scoth 1.0、原始 R 程式','作者 R 評分／成本 helper，加上自訂 R 遞迴擴充'],
      ['資料','38 個單變量＋4 個多變量','相同 42 個資料集'],
      ['離群值','直接使用原始觀測','孤立尖峰修補，k=4、修補比例上限 2%'],
      ['線性成本','原始序列的線性平方誤差','固定修補後序列的同一線性平方誤差'],
      ['評分','作者 Algorithm 1','相同評分器，輸入為固定修補後序列'],
      ['遞迴','作者 Algorithm 2','前兩層抑制距離小於 3 樣本的重複候選，第 3 層起釋放'],
      ['共用門檻','0.10','0.09'],
      ['層數','level 0＋10 個非零層級','相同'],
      ['最終層級','主要表格依正確標註選層','主要表格同樣依正確標註選層'],
      ['多變量','原單位下加總特徵成本','相同原單位慣例，逐特徵做固定修補'],
      ['原始碼完整性','基準保持未修改','新增檔案實作，未改動作者來源或基準輸出'],
    ])]
    metrics=[]
    for label,key,sd in [('平均 F1（主要指標）','F1_mean','F1_sd'),
                         ('F1-biased，同一組預測','F1_biased_mean','F1_biased_sd'),
                         ('Covering，同一組預測','covering_mean','covering_sd')]:
        metrics.append([label,f'{f(a[key])} ± {f(a[sd])}',f'{f(b[key])} ± {f(b[sd])}',f'{float(b[key])-float(a[key]):+.4f}'])
    for label,key in [('Micro precision','micro_precision'),('Micro recall','micro_recall'),
                       ('平均誤報數／資料集','FP_mean'),('平均漏報數／資料集','FN_mean'),
                       ('平均預測切點數／資料集','predictions_mean')]:
        metrics.append([label,f(a[key]),f(b[key]),f'{float(b[key])-float(a[key]):+.4f}'])
    for label,key in [('總正確切點 TP','TP_total'),('總誤報 FP','FP_total'),('總漏報 FN','FN_total')]:
        metrics.append([label,int(float(a[key])),int(float(b[key])),f'{int(float(b[key])-float(a[key])):+d}'])
    parts+=['## 相同共用設定規則下的 42 個資料集結果',table(['指標','原方法','Delayed3','差值：新−原'],metrics),
      'F1 為跨資料集平均；Micro precision/recall 為合計切點計算，兩者不可混為同一加權方式。',
      'F1-biased 與 covering 用上述依 F1 選出的同一組預測重算；不是各自另調至最佳，因此不能直接拿它們與論文 Oracle 的 0.92、0.82 混比。']
    oracle={r['pipeline']:r for r in read(root/'family_oracle_summary.csv')}
    parts+=['## 逐資料集 Oracle 上限',table(['條件','原方法','新方法'],[
      ['各資料集選成本分支、門檻與層級',f(oracle['Original']['F1_mean']),f(oracle['Delayed3']['F1_mean'])]]),
      '兩個家族都保留作者原均值分支；新家族只替換線性分支。這是使用答案選最佳的上限，非可直接部署表現。']
    cv=read(root/'fixed_method_cv_summary.csv')
    parts+=['## 固定版本的分組五折交叉驗證',table(['選層規則','原線性方法','固定 Delayed3'],[
      ['依標註選測試層級',f(next(r['F1_mean'] for r in cv if r['method']=='Original' and r['rule']=='OracleLevel')),
       f(next(r['F1_mean'] for r in cv if r['method']=='Delayed3' and r['rule']=='OracleLevel'))],
      ['固定層級，由訓練折決定',f(next(r['F1_mean'] for r in cv if r['method']=='Original' and r['rule']=='FixedLevel')),
       f(next(r['F1_mean'] for r in cv if r['method']=='Delayed3' and r['rule']=='FixedLevel'))]]),
      '同來源資料不跨折；每折只用訓練資料選門檻／固定層級。所有資料先前已被研究者檢視，此處仍屬探索性內部驗證。',
      '此表固定比較原線性方法與 Delayed3，未在測試折重新挑選候選方法。']
    stress=read(Path('results/latest_r/stress/summary.csv'))
    cases=[('1% 尖峰','spikes1'),('5% 尖峰','spikes5'),('3 樣本短事件','short3'),('兩個相近短事件','nearby_changes')]
    parts+=['## 同一組新種子壓力測試',table(['情境','原線性方法 F1','Delayed3 F1'],[
      [name,f(next(r['F1_mean'] for r in stress if r['scenario']==key and r['method']=='OriginalLinear' and r['rule']=='OracleLevel')),
       f(next(r['F1_mean'] for r in stress if r['scenario']==key and r['method']=='Delayed3' and r['rule']=='OracleLevel'))]
      for name,key in cases]),'固定門檻 0.09、依標註選層，每情境相同 20 個新種子；不是各方法另挑最佳種子。']
    times={r['method']:r for r in read(root/'timing_summary.csv')}
    parts+=['## 同機端到端計時',table(['計時項目','原方法','Delayed3'],[
      ['每資料集平均秒數',f(times['Original']['mean_seconds']),f(times['Delayed3']['mean_seconds'])],
      ['每資料集中位秒數',f(times['Original']['median_seconds']),f(times['Delayed3']['median_seconds'])],
      ['全部 42 個資料集累計秒數',f(times['Original']['total_seconds']),f(times['Delayed3']['total_seconds'])]]),
      '同一台電腦與 R 環境；每資料集各跑 3 次取中位數，再跨資料集彙整。交錯執行順序，無保存分數重用、無成本快取。包含前處理、評分、10 層選擇；不含訓練網格搜尋、資料讀取與指標計算。這是本機描述性計時，不是跨硬體效能保證。']
    difference=read(root/'paired_difference.csv')[0]
    parts+=['## 不確定性與限制',table(['項目','結果'],[
      ['42 個資料集勝／平／負',f"{difference['wins']}／{difference['ties']}／{difference['losses']}"],
      ['主要 F1 平均差',f(difference['mean_delta'])],
      ['按來源群 bootstrap 描述性 95% 區間',f"[{f(difference['ci95_lower'])}, {f(difference['ci95_upper'])}]"],
      ['可否宣稱穩定顯著勝出','不能；區間包含 0，且資料已重複用於開發'],
      ['自動決定最終粒度','尚未解決；主要表格仍使用標註選層'],
      ['峰值記憶體與超長序列擴展性','尚未公平量測，不能下結論'],
      ['密集污染','5% 尖峰仍表現不佳'],
      ['新增假設','稀疏孤立尖峰、3 樣本近距離候選抑制、指定層級釋放']])]
    pairs=read(root/'paired_by_dataset.csv')
    parts+=['## 全部 42 個資料集逐筆比較',table(['資料集','原 F1','新 F1','差值','原 FP','新 FP','原 FN','新 FN'],[
      [r['dataset'],f(r['F1_old']),f(r['F1_new']),f"{float(r['delta']):+.4f}",
       int(float(r['FP_old'])),int(float(r['FP_new'])),int(float(r['FN_old'])),int(float(r['FN_new']))]
      for r in pairs])]
    (root/'comparison_tables.md').write_text('\n\n'.join(parts)+'\n',encoding='utf-8')
    print('Comprehensive Markdown tables saved.')


if __name__=='__main__': main()
