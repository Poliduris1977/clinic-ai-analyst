// Агрегация по когортам: количество пациентов, суммарная выручка и LTV12.
let
    Grouped = Table.Group(qNewPatients, {"CohortMonth"}, {
        {"PatientCount", each Table.RowCount(_), Int64.Type},
        {"SumRevenue", each List.Sum([RevTotal]), type number}
    }),
    AddLTV = Table.AddColumn(Grouped, "LTV12", each [SumRevenue] / [PatientCount], type number),
    Sorted = Table.Sort(AddLTV, {{"CohortMonth", Order.Ascending}})
in
    Sorted
