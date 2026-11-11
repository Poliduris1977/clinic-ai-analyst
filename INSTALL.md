# Установка и запуск

## Что нужно
- Python 3.12 или новее (проверено на 3.12.3)
- LibreOffice (необязательно, но нужен для пересчёта формул в xlsx: без него книги откроются в Excel и пересчитаются там, а проверки `check_controls` не смогут прочитать значения формул)
- Для проверки дашборда в браузере (необязательно): `pip install playwright` и `playwright install chromium`

## Шаги
1. Распаковать архив в папку, например `clinic-ai-analyst`.
2. Открыть терминал в этой папке.
3. (рекомендуется) виртуальное окружение:
   - Windows: `python -m venv .venv` и `.venv\Scripts\activate`
   - macOS/Linux: `python3 -m venv .venv` и `source .venv/bin/activate`
4. `pip install -r requirements.txt`
5. `python src/run_chain.py` (около минуты). Скрипт сам создаёт папку `data/`: синтетические данные, сверка, все книги, дашборд, агент, проверки.

## Что получится
В `data/reports/`: P&L, план-факт, Doctors_2025.xlsx, CashFlow_2025.xlsx, PatientLTV_2025.xlsx, Forecast_2026Q1.xlsx, **Dashboard_2025.html** (открывается двойным щелчком, без сервера) и агент.
В конце цепочки должно быть: `test_agent` 44 из 44, `check_controls` 40 из 40, в дашборде 87 проверок, SQL-контролей 31 из 31, `check_excel` 93 из 93.

## Отдельные команды
- Пересобрать только дашборд: `python src/dashboard/build_dashboard.py data/reports/Dashboard_2025.html`
- Проверки контролей: `python src/check_controls.py`
- Проверка снапшотов Excel-трека: `python src/check_excel.py` (самопроверка: `--self-test`)
- SQL-слой (базы и 9 запросов): `python src/sql/run_sql.py`, описание в `sql/README.md`
- Слепой тест: `python src/blind/inject_errors_v2.py`, затем `python src/blind/compare_runs.py`

## Если что-то не так
- «soffice не найден»: установить LibreOffice или добавить его в PATH.
- Версии pandas/numpy новее проверенных обычно работают; расхождения контролей покажет `check_controls`.
- Решения по проекту и причины: `docs/KEY_DECISIONS.md`, допущения: `docs/ASSUMPTIONS.md`.
