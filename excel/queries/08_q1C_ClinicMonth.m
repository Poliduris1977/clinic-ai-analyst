// Выручка 1С по клинике и месяцу. Только проводки Кт 90.01 при Дт 62.01 или 62.02.
let
    Filtered = Table.SelectRows(
        qPostings,
        each [credit] = "90.01" and ([debit] = "62.01" or [debit] = "62.02")),
    AddPeriod = Table.AddColumn(
        Filtered, "Period",
        each Date.ToText([date], "yyyy-MM", "en-US"), type text),
    Grouped = Table.Group(
        AddPeriod,
        {"clinic_id", "Period"},
        {{"C1", each List.Sum([amount]), type number}}),
    Sorted = Table.Sort(Grouped, {{"clinic_id", Order.Ascending}, {"Period", Order.Ascending}})
in
    Sorted
