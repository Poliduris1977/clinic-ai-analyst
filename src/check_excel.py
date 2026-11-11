"""
Проверка Excel-трека (Power Query / Power Pivot) по values-only снапшотам.

Запуск из корня проекта:        python3 src/check_excel.py
Проверка самого скрипта:        python3 src/check_excel.py --self-test

Что делает: открывает оба снапшота из excel/snapshots (openpyxl, data_only=True) и сверяет
значения с контрольными цифрами из excel/control_map.json. Значения ищутся по имени листа
и заголовку, а не по адресу ячейки. Печатает PASS/FAIL по каждому контролю и итог
«Excel controls: N/N passed»; код выхода 1 при любом расхождении или недостающем файле.

Ничего не пересчитывает и не меняет: только читает снапшоты. Power Query и DAX здесь
не выполняются (LibreOffice их не считает): снапшоты делаются вручную в Excel из живой
книги, снапшоты собираются вручную. При осознанном изменении метода обновить
excel/control_map.json.
"""
import argparse
import json
import re
import shutil
import sys
import tempfile
from collections import Counter
from pathlib import Path

import openpyxl

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MAP = ROOT / "excel" / "control_map.json"
DEFAULT_SNAPSHOTS = ROOT / "excel" / "snapshots"
PERIOD = re.compile(r"^\d{4}-\d{2}$")
MISSING = object()


# ---------- чтение листов ----------
def sheet_rows(wb, name):
    if name not in wb.sheetnames:
        raise KeyError(f"нет листа «{name}»")
    return [list(r) for r in wb[name].iter_rows(values_only=True)]


def table(rows):
    """Первая непустая строка это заголовок; полностью пустые строки пропускаются."""
    rows = [r for r in rows if any(c is not None for c in r)]
    if not rows:
        return [], []
    head = [str(c) if c is not None else None for c in rows[0]]
    return head, [dict(zip(head, r)) for r in rows[1:]]


def need_column(head, name, sheet):
    if name not in head:
        raise KeyError(f"на листе «{sheet}» нет столбца «{name}»")


def data_rows(rows, sheet, column):
    """Строки таблицы, где заполнен столбец column (пустая строка Excel не считается)."""
    head, recs = table(rows)
    need_column(head, column, sheet)
    return [r for r in recs if r.get(column) not in (None, "")]


def parse_pivot(rows, sheet):
    """Сводная: строка «Названия строк», над ней месяцы (подпись в первом столбце пары),
    справа столбцы «Итог <мера>»."""
    hdr = next((i for i, r in enumerate(rows) if r and r[0] == "Названия строк"), None)
    if hdr is None or hdr == 0:
        raise KeyError(f"на листе «{sheet}» не найдена строка «Названия строк»")
    months, measures = rows[hdr - 1], rows[hdr]
    cols, cur = {}, None
    for j in range(1, max(len(months), len(measures))):
        m = months[j] if j < len(months) else None
        meas = measures[j] if j < len(measures) else None
        if isinstance(m, str) and PERIOD.match(m):
            cur = m
        elif isinstance(m, str) and m.startswith("Итог "):
            cols[("TOTAL", m[5:])] = j
            cur = None
            continue
        if cur and meas:
            cols[(cur, meas)] = j
    body = {r[0]: r for r in rows[hdr + 1:] if r and r[0]}
    return cols, body


def pivot_value(wb, sheet, row, period, measure):
    cols, body = parse_pivot(sheet_rows(wb, sheet), sheet)
    if row not in body:
        raise KeyError(f"на листе «{sheet}» нет строки «{row}»")
    if (period, measure) not in cols:
        raise KeyError(f"на листе «{sheet}» нет столбца {period} / {measure}")
    return body[row][cols[(period, measure)]]


# ---------- виды проверок: каждая возвращает полученное значение ----------
def get_value(wb, c):
    k, s = c["kind"], c.get("sheet")
    if k == "meta":
        for r in sheet_rows(wb, s):
            if r and r[0] == c["key"]:
                return r[1]
        raise KeyError(f"на листе «{s}» нет ключа «{c['key']}»")
    if k == "kv":
        head, recs = table(sheet_rows(wb, s))
        need_column(head, c["key_column"], s)
        need_column(head, c["value_column"], s)
        for r in recs:
            if r[c["key_column"]] == c["key"]:
                return r[c["value_column"]]
        raise KeyError(f"на листе «{s}» нет строки «{c['key']}»")
    if k == "model":   # имена мер в одной строке, значения строкой ниже
        rows = sheet_rows(wb, s)
        for i, r in enumerate(rows):
            for j, v in enumerate(r):
                if v == c["measure"] and i + 1 < len(rows):
                    return rows[i + 1][j]
        raise KeyError(f"на листе «{s}» нет меры «{c['measure']}»")
    if k == "table_rows":
        return len(data_rows(sheet_rows(wb, s), s, c["nonempty_column"]))
    if k == "column_sum":
        head, recs = table(sheet_rows(wb, s))
        need_column(head, c["column"], s)
        return sum(r[c["column"]] for r in recs if isinstance(r[c["column"]], (int, float)))
    if k == "count_true":
        head, recs = table(sheet_rows(wb, s))
        need_column(head, c["column"], s)
        return sum(1 for r in recs if r[c["column"]] is True)
    if k == "recon_material_cells":
        _, recs = table(sheet_rows(wb, s))
        return {f"{r['clinic_id']}|{r['Period']}": r["Diff"] for r in recs if r["Material"] is True}
    if k == "rule_counts":
        return dict(Counter(r["Rule"] for r in data_rows(sheet_rows(wb, s), s, "Rule")))
    if k == "rule_amounts":
        return sorted(r["Amount"] for r in data_rows(sheet_rows(wb, s), s, "Rule"))
    if k == "cohort_cell":
        head, recs = table(sheet_rows(wb, s))
        need_column(head, c["column"], s)
        for r in recs:
            if r["CohortMonth"] == c["cohort"]:
                return r[c["column"]]
        raise KeyError(f"на листе «{s}» нет когорты {c['cohort']}")
    if k == "pivot_cell":
        return pivot_value(wb, s, c["row"], c["period"], c["measure"])
    if k == "pivot_series":
        return [pivot_value(wb, s, c["row"], p, c["measure"]) for p in c["periods"]]
    raise ValueError(f"неизвестный вид проверки: {k}")


def same(got, want, tol):
    if isinstance(want, dict):
        return (isinstance(got, dict) and set(got) == set(want)
                and all(same(got[k], want[k], tol) for k in want))
    if isinstance(want, list):
        return (isinstance(got, list) and len(got) == len(want)
                and all(same(g, w, tol) for g, w in zip(got, want)))
    if isinstance(want, (int, float)) and not isinstance(want, bool):
        try:
            return abs(float(got) - float(want)) <= tol
        except (TypeError, ValueError):
            return False
    return got == want


def run_checks(snap_dir, cmap):
    """Возвращает список (ok, набор, id, название, получено, ожидалось)."""
    out = []
    for dataset, fname in cmap["snapshots"].items():
        path = Path(snap_dir) / fname
        if not path.exists():
            out.append((False, dataset, "file", f"снапшот {fname}", "файла нет", "файл есть"))
            continue
        wb = openpyxl.load_workbook(path, data_only=True)
        for c in cmap["checks"]:
            if dataset not in c["expected"]:
                continue
            want = c["expected"][dataset]
            try:
                got = get_value(wb, c)
            except Exception as e:   # ошибка чтения считается провалом проверки
                got = f"ошибка: {type(e).__name__}: {e}"
            out.append((same(got, want, c.get("tol", 0)), dataset, c["id"], c["title"], got, want))
    return out


def fmt(v):
    if isinstance(v, float):
        return f"{v:,.4f}"
    s = json.dumps(v, ensure_ascii=False) if isinstance(v, (dict, list)) else str(v)
    return s if len(s) <= 140 else s[:137] + "..."


# ---------- проверка самого скрипта ----------
def self_test(snap_dir, cmap):
    """Искажает по одному значению в копиях снапшотов; каждое искажение обязано дать провал."""
    base = run_checks(snap_dir, cmap)
    if not all(r[0] for r in base):
        print("Self-test: исходные снапшоты не проходят проверку, искажать нечего")
        return 1

    def find(ws, text):
        for row in ws.iter_rows():
            for cell in row:
                if cell.value == text:
                    return cell
        raise KeyError(text)

    def m_controls(wb):
        cell = find(wb["Controls"], "revenue_erp"); cell.offset(0, 1).value += 1
    def m_model(wb):
        cell = find(wb["Model"], "Profit Before Tax"); cell.offset(1, 0).value += 0.5
    def m_recon(wb):
        wb["Recon"]["C2"].value += 1
    def m_registry(wb):
        wb["Registry"].delete_rows(2)
    def m_cohorts(wb):
        cell = find(wb["Cohorts"], "2025-01"); cell.offset(0, 1).value -= 1
    def m_pivot(wb):
        cell = find(wb["Pivot"], "Общий итог"); cell.offset(0, 1).value += 1
    def m_rule(wb):
        wb["qRule_NoDoctor"]["F2"].value += 100
    def m_meta(wb):
        wb["Meta"]["B1"].value = "corrected"

    mutations = [("Controls: revenue_erp +1", m_controls), ("Model: Profit Before Tax +0,5", m_model),
                 ("Recon: ERP первой строки +1", m_recon), ("Registry: удалена строка", m_registry),
                 ("Cohorts: пациентов в январе -1", m_cohorts), ("Pivot: итог января +1", m_pivot),
                 ("qRule_NoDoctor: сумма находки +100", m_rule), ("Meta: подменён набор", m_meta)]
    bad = 0
    for name, fn in mutations:
        with tempfile.TemporaryDirectory() as tmp:
            for f in cmap["snapshots"].values():
                shutil.copy(Path(snap_dir) / f, tmp)
            p = Path(tmp) / cmap["snapshots"]["dirty"]
            wb = openpyxl.load_workbook(p)
            fn(wb)
            wb.save(p)
            fails = [r for r in run_checks(tmp, cmap) if not r[0]]
        status = "поймано" if fails else "НЕ ПОЙМАНО"
        bad += 0 if fails else 1
        print(f"  {status}: {name} (провалов: {len(fails)})")
    print("Self-test: " + ("все искажения пойманы" if not bad else f"не поймано искажений: {bad}"))
    return 1 if bad else 0


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--map", default=str(DEFAULT_MAP), help="control_map.json")
    ap.add_argument("--snapshots", default=str(DEFAULT_SNAPSHOTS), help="папка со снапшотами")
    ap.add_argument("--self-test", action="store_true", help="проверить сам скрипт на искажённых копиях")
    ap.add_argument("--quiet", action="store_true", help="печатать только FAIL и итог")
    a = ap.parse_args()
    cmap = json.loads(Path(a.map).read_text(encoding="utf-8"))
    if a.self_test:
        sys.exit(self_test(a.snapshots, cmap))
    res = run_checks(a.snapshots, cmap)
    for ok, ds, cid, title, got, want in res:
        if ok and a.quiet:
            continue
        line = f"{'PASS' if ok else 'FAIL'} [{ds}] {title}: получено {fmt(got)}"
        print(line if ok else line + f", ожидалось {fmt(want)}")
    passed = sum(1 for r in res if r[0])
    print(f"\nExcel controls: {passed}/{len(res)} passed")
    sys.exit(0 if passed == len(res) else 1)


if __name__ == "__main__":
    main()
