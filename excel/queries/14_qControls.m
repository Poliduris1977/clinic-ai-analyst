// Сводная панель контроля. Значения берутся напрямую из запросов, без ручного ввода.
let
    // Формируем таблицу из списка списков (Metric, Value)
    Source = Table.FromRows({
        {"revenue_erp", List.Sum(qERP_ClinicMonth[ERP])},
        {"revenue_1c", List.Sum(q1C_ClinicMonth[C1])},
        {"revenue_diff", List.Sum(qRecon[Diff])},
        {"cells_material", Table.RowCount(Table.SelectRows(qRecon, each [Material] = true))},
        {"no_doctor_count", Table.RowCount(qRule_NoDoctor)},
        {"price_below_count", Table.RowCount(qRule_PriceBelowList)},
        {"duplicates_count", Table.RowCount(qRule_Duplicates)}
    }, {"Metric", "Value"}),
    
    // Явно задаем типы
    Typed = Table.TransformColumnTypes(Source, {
        {"Metric", type text}, 
        {"Value", type number}
    }, "en-US")
in
    Typed
