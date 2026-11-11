// Загрузка врачей. Типы заданы явно.
let
    Source = fnReadCsv("doctors.csv"),
    Typed = Table.TransformColumnTypes(Source, {
        {"doctor_id", type text}, {"doctor_name", type text}, 
        {"direction_code", type text}, {"direction", type text}, 
        {"specialty", type text}, {"clinic_id", type text}, 
        {"grade", type text}, {"pay_pct", type number}, 
        {"popularity_weight", type number}, {"hire_date", type date}
    }, "en-US")
in
    Typed
