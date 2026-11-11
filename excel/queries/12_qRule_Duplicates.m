// Правило 3: Поиск дублей завершенных визитов.
// Ключ: patient_id, doctor_id (null -> ""), clinic_id, visit_date, visit_time, состав услуг.
let
    // 1. Формируем состав услуг по каждому визиту
    SortedItems = Table.Sort(qItems, {{"visit_id", Order.Ascending}, {"item_id", Order.Ascending}}),
    AddItemString = Table.AddColumn(SortedItems, "ItemString", 
        each Text.From([service_id], "en-US") & "|" & 
             Text.From([qty], "en-US") & "|" & 
             Text.From([price_fact], "en-US"), type text),
    GroupedItems = Table.Group(AddItemString, {"visit_id"}, {
        {"Composition", each Text.Combine([ItemString], ";"), type text},
        {"VisitRevenue", each List.Sum([revenue]), type number}
    }),
    
    // 2. Присоединяем состав к визитам и формируем общий ключ
    FilteredVisits = Table.SelectRows(qVisits, each [status] = "completed"),
    Joined = Table.NestedJoin(FilteredVisits, {"visit_id"}, GroupedItems, {"visit_id"}, "Items", JoinKind.Inner),
    Expanded = Table.ExpandTableColumn(Joined, "Items", {"Composition", "VisitRevenue"}, {"Composition", "VisitRevenue"}),
    AddKey = Table.AddColumn(Expanded, "DupKey", each 
        Text.From([patient_id], "en-US") & "|" & 
        (if [doctor_id] = null then "" else [doctor_id]) & "|" & 
        Text.From([clinic_id], "en-US") & "|" & 
        Date.ToText([visit_date], "yyyy-MM-dd", "en-US") & "|" & 
        Text.From([visit_time], "en-US") & "|" & 
        [Composition], type text),
        
    // 3. Группируем по ключу, сортируем по visit_id. Первый - оригинал, остальные - дубли.
    GroupedKeys = Table.Group(AddKey, {"DupKey"}, {
        {"AllVisits", each Table.Sort(_, {{"visit_id", Order.Ascending}}), type table}
    }),
    
    // Оставляем только те группы, где больше 1 визита
    FilteredDuplicates = Table.SelectRows(GroupedKeys, each Table.RowCount([AllVisits]) > 1),
    
    // Извлекаем таблицы дублей (пропускаем первую строку)
    AddedDups = Table.AddColumn(FilteredDuplicates, "Dups", each Table.Skip([AllVisits], 1)),
    ExpandedDups = Table.ExpandTableColumn(AddedDups, "Dups", 
        {"visit_id", "clinic_id", "direction_code", "visit_date", "VisitRevenue"}, 
        {"record_id", "clinic_id", "direction_code", "visit_date", "Amount"}),
        
    // 4. Форматируем вывод
    AddPeriod = Table.AddColumn(ExpandedDups, "Period", each Date.ToText([visit_date], "yyyy-MM", "en-US"), type text),
    AddRule = Table.AddColumn(AddPeriod, "Rule", each "Duplicates", type text),
    Selected = Table.SelectColumns(AddRule, {"Rule", "Period", "clinic_id", "direction_code", "record_id", "Amount"}),
    Typed = Table.TransformColumnTypes(Selected, {
        {"Rule", type text}, {"Period", type text}, {"clinic_id", type text}, 
        {"direction_code", type text}, {"record_id", type text}, {"Amount", type number}
    }, "en-US")
in
    Typed
