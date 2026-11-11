// Справочник дат (Календарь) на 2025 год для корректной фильтрации фактов.
let
    StartDate = #date(2025, 1, 1),
    EndDate = #date(2025, 12, 31),
    // Генерируем непрерывный список дат
    DateList = List.Dates(StartDate, Duration.Days(EndDate - StartDate) + 1, #duration(1, 0, 0, 0)),
    // Преобразуем список в таблицу
    ConvertedToTable = Table.FromList(DateList, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    RenamedColumns = Table.RenameColumns(ConvertedToTable, {{"Column1", "Date"}}),
    
    // Задаем типы и вычисляем колонки с культурой en-US
    TypedDate = Table.TransformColumnTypes(RenamedColumns, {{"Date", type date}}, "en-US"),
    AddMonthKey = Table.AddColumn(TypedDate, "MonthKey", each Date.ToText([Date], "yyyy-MM", "en-US"), type text),
    AddMonthNo = Table.AddColumn(AddMonthKey, "MonthNo", each Date.Month([Date]), Int64.Type),
    AddMonthName = Table.AddColumn(AddMonthNo, "MonthName", each Date.ToText([Date], "MMMM", "en-US"), type text)
in
    AddMonthName
