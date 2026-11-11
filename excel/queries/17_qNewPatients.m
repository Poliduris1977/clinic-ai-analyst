// Новые пациенты (первый визит >= 2025-01-01), у которых был хотя бы один completed визит.
// CohortMonth = месяц первого completed визита. RevTotal = выручка за 2025 год.
let
    // 1. Берем новых пациентов
    FilteredPatients = Table.SelectRows(qPatients, each [first_visit_date] >= #date(2025, 1, 1)),
    
    // 2. Присоединяем к ним выручку (Inner Join отсекает тех, у кого нет completed визитов)
    Joined = Table.NestedJoin(FilteredPatients, {"patient_id"}, qVisitRevenue, {"patient_id"}, "VR", JoinKind.Inner),
    Expanded = Table.ExpandTableColumn(Joined, "VR", {"visit_date", "Revenue"}, {"visit_date", "Revenue"}),
    
    // 3. Фильтруем строго по 2025 году (на случай аномалий с датами)
    Filter2025 = Table.SelectRows(Expanded, each Date.Year([visit_date]) = 2025),
    
    // 4. Группируем по пациенту: минимальная дата визита = когорта, сумма выручки = RevTotal
    Grouped = Table.Group(Filter2025, {"patient_id"}, {
        {"CohortMonth", each Date.ToText(List.Min([visit_date]), "yyyy-MM", "en-US"), type text},
        {"RevTotal", each List.Sum([Revenue]), type number}
    })
in
    Grouped
