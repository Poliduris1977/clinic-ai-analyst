// Выручка по каждому завершенному визиту.
// Присоединяем qItems к визитам со статусом completed.
let
    FilteredVisits = Table.SelectRows(qVisits, each [status] = "completed"),
    Joined = Table.NestedJoin(FilteredVisits, {"visit_id"}, qItems, {"visit_id"}, "Items", JoinKind.Inner),
    Expanded = Table.ExpandTableColumn(Joined, "Items", {"revenue"}, {"revenue"}),
    Grouped = Table.Group(Expanded, {"visit_id", "patient_id", "visit_date"}, 
        {{"Revenue", each List.Sum([revenue]), type number}})
in
    Grouped
