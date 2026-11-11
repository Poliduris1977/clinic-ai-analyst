// Объединяем результаты трех правил и материальные расхождения из qRecon.
// Для qRecon формируем Rule = "revenue_cell", Amount = Diff, record_id = clinic_id & "|" & Period.
let
    // 1. Берем три готовые таблицы правил (у них уже одинаковые колонки)
    T_NoDoc = qRule_NoDoctor,
    T_Price = qRule_PriceBelowList,
    T_Dups  = qRule_Duplicates,

    // 2. Берем qRecon и оставляем только Material = true
    T_Recon_Src = Table.SelectRows(qRecon, each [Material] = true),
    
    // Добавляем Rule и direction_code (в qRecon его нет, ставим null)
    T_Recon_Add = Table.AddColumn(T_Recon_Src, "Rule", each "revenue_cell", type text),
    T_Recon_Dir = Table.AddColumn(T_Recon_Add, "direction_code", each null, type nullable text),
    
    // Формируем record_id = clinic_id & "|" & Period
    T_Recon_Rec = Table.AddColumn(T_Recon_Dir, "record_id", 
        each Text.From([clinic_id], "en-US") & "|" & Text.From([Period], "en-US"), type text),
    
    // Переименовываем Diff в Amount
    T_Recon_Ren = Table.RenameColumns(T_Recon_Rec, {{"Diff", "Amount"}}),
    
    // Оставляем только 6 нужных колонок в правильном порядке
    T_Recon_Fin = Table.SelectColumns(T_Recon_Ren, {"Rule", "Period", "clinic_id", "direction_code", "record_id", "Amount"}),

    // 3. Объединяем все 4 таблицы
    Combined = Table.Combine({T_NoDoc, T_Price, T_Dups, T_Recon_Fin}),

    // 4. Выравниваем типы данных (на случай, если где-то был null)
    Typed = Table.TransformColumnTypes(Combined, {
        {"Rule", type text}, {"Period", type text}, {"clinic_id", type text}, 
        {"direction_code", type text}, {"record_id", type text}, {"Amount", type number}
    }, "en-US")
in
    Typed
