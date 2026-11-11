// Полное внешнее соединение ERP и 1С по (clinic_id, Period).
// Пропуски заменяем на 0, считаем Diff и помечаем Material.
let
    Joined = Table.NestedJoin(
        qERP_ClinicMonth, {"clinic_id", "Period"},
        q1C_ClinicMonth, {"clinic_id", "Period"},
        "C1T", JoinKind.FullOuter),
    Expanded = Table.ExpandTableColumn(
        Joined, "C1T",
        {"clinic_id", "Period", "C1"},
        {"clinic_id_R", "Period_R", "C1"}),
    AddClinic = Table.AddColumn(
        Expanded, "clinic_id_final",
        each if [clinic_id] = null then [clinic_id_R] else [clinic_id], type text),
    AddPeriod = Table.AddColumn(
        AddClinic, "Period_final",
        each if [Period] = null then [Period_R] else [Period], type text),
    FillERP = Table.ReplaceValue(AddPeriod, null, 0, Replacer.ReplaceValue, {"ERP"}),
    FillC1  = Table.ReplaceValue(FillERP,  null, 0, Replacer.ReplaceValue, {"C1"}),
    Typed = Table.TransformColumnTypes(
        FillC1,
        {{"ERP", type number}, {"C1", type number}},
        "en-US"),
    AddDiff = Table.AddColumn(Typed, "Diff", each [ERP] - [C1], type number),
    AddMaterial = Table.AddColumn(
        AddDiff, "Material",
        each Number.Abs([Diff]) > pThreshold, type logical),
    AddComment = Table.AddColumn(
        AddMaterial, "Comment",
        each
            if Number.Abs([Diff]) > 0 and Number.Abs([Diff]) <= pThreshold then "округление цен"
            else if [Material] then "расхождение"
            else null,
        type nullable text),
    Selected = Table.SelectColumns(
        AddComment,
        {"clinic_id_final", "Period_final", "ERP", "C1", "Diff", "Material", "Comment"}),
    Renamed = Table.RenameColumns(
        Selected,
        {{"clinic_id_final", "clinic_id"}, {"Period_final", "Period"}}),
    Sorted = Table.Sort(
        Renamed,
        {{"clinic_id", Order.Ascending}, {"Period", Order.Ascending}})
in
    Sorted
