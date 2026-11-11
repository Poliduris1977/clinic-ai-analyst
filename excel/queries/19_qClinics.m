// Загрузка клиник. Типы заданы явно.
let
    Source = fnReadCsv("clinics.csv"),
    Typed = Table.TransformColumnTypes(Source, {
        {"clinic_id", type text}, {"clinic_name", type text}, 
        {"district", type text}, {"directions", type text}, 
        {"rent_month", type number}
    }, "en-US")
in
    Typed
