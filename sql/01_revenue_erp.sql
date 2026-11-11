-- Контроль 1. Выручка по данным ERP (визиты и позиции услуг).
-- Ожидается 825 211 700 ₽ на исправленных данных (PnL: контрольные цифры в src/check_controls.py).
SELECT ROUND(SUM(revenue), 2)  AS revenue_erp,
       COUNT(*)                AS items
FROM visit_items;
