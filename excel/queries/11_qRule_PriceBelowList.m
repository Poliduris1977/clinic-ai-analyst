// Правило 2: Позиции, где фактическая цена ниже ожидаемой более чем на 100 руб.
// ExpectedPrice = Round(list_price * (1 - discount/100) / 100) * 100.
// Amount = -(ExpectedPrice - price_fact) * qty (отрицательный недобор).
let
    FilteredVisits = Table.SelectRows(qVisits, each [status] = "completed"),
    Joined = Table.NestedJoin(qItems, {"visit_id"}, FilteredVisits, {"visit_id"}, "Visits", JoinKind.Inner),
    Expanded = Table.ExpandTableColumn(Joined, "Visits", {"clinic_id", "direction_code", "visit_date"}, {"clinic_id", "direction_code", "visit_date"}),
    
    // Считаем ожидаемую цену
    AddExpected = Table.AddColumn(Expanded, "ExpectedPrice", 
        each Number.Round([list_price_at_date] * (1 - [discount_pct] / 100) / 100, 0) * 100, type number),
    
    // Фильтруем: цена факт ниже ожидаемой более чем на 100
    FilteredRule = Table.SelectRows(AddExpected, each [price_fact] < [ExpectedPrice] - 100),
    
    // Считаем недобор (отрицательный)
    AddAmount = Table.AddColumn(FilteredRule, "Amount", each -([ExpectedPrice] - [price_fact]) * [qty], type number),
    AddPeriod = Table.AddColumn(AddAmount, "Period", each Date.ToText([visit_date], "yyyy-MM", "en-US"), type text),
    AddRule = Table.AddColumn(AddPeriod, "Rule", each "PriceBelowList", type text),
    Renamed = Table.RenameColumns(AddRule, {{"item_id", "record_id"}}),
    Selected = Table.SelectColumns(Renamed, {"Rule", "Period", "clinic_id", "direction_code", "record_id", "Amount"}),
    Typed = Table.TransformColumnTypes(Selected, {
        {"Rule", type text}, {"Period", type text}, {"clinic_id", type text}, 
        {"direction_code", type text}, {"record_id", type text}, {"Amount", type number}
    }, "en-US")
in
    Typed
