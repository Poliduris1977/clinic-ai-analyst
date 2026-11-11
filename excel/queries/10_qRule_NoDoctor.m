// Правило 1: Визиты со статусом completed, но без врача (doctor_id = null).
// Amount = сумма выручки по визиту.
let
    FilteredVisits = Table.SelectRows(qVisits, each [status] = "completed" and [doctor_id] = null),
    Joined = Table.NestedJoin(FilteredVisits, {"visit_id"}, qItems, {"visit_id"}, "Items", JoinKind.Inner),
    Expanded = Table.ExpandTableColumn(Joined, "Items", {"revenue"}, {"revenue"}),
    Grouped = Table.Group(Expanded, {"visit_id", "clinic_id", "direction_code", "visit_date"}, 
        {{"Amount", each List.Sum([revenue]), type number}}),
    AddPeriod = Table.AddColumn(Grouped, "Period", each Date.ToText([visit_date], "yyyy-MM", "en-US"), type text),
    AddRule = Table.AddColumn(AddPeriod, "Rule", each "NoDoctor", type text),
    Renamed = Table.RenameColumns(AddRule, {{"visit_id", "record_id"}}),
    Selected = Table.SelectColumns(Renamed, {"Rule", "Period", "clinic_id", "direction_code", "record_id", "Amount"}),
    Typed = Table.TransformColumnTypes(Selected, {
        {"Rule", type text}, {"Period", type text}, {"clinic_id", type text}, 
        {"direction_code", type text}, {"record_id", type text}, {"Amount", type number}
    }, "en-US")
in
    Typed
