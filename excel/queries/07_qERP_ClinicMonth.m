// Выручка ERP по клинике и месяцу. qItems join qVisits по visit_id.
// Period = первые 7 символов даты в формате yyyy-MM.
let
    Joined = Table.NestedJoin(
        qItems, {"visit_id"},
        qVisits, {"visit_id"},
        "V", JoinKind.Inner),
    Expanded = Table.ExpandTableColumn(
        Joined, "V",
        {"clinic_id", "visit_date"},
        {"clinic_id", "visit_date"}),
    AddPeriod = Table.AddColumn(
        Expanded, "Period",
        each Date.ToText([visit_date], "yyyy-MM", "en-US"), type text),
    Grouped = Table.Group(
        AddPeriod,
        {"clinic_id", "Period"},
        {{"ERP", each List.Sum([revenue]), type number}}),
    Sorted = Table.Sort(Grouped, {{"clinic_id", Order.Ascending}, {"Period", Order.Ascending}})
in
    Sorted
