// Загрузка пациентов. Типы заданы явно, автоопределение отключено.
let
    Source = fnReadCsv("patients.csv"),
    Typed = Table.TransformColumnTypes(Source, {
        {"patient_id", type text}, 
        {"first_visit_date", type date},
        {"home_clinic_id", type text}, 
        {"birth_year", Int64.Type}, 
        {"source", type text}
    }, "en-US")
in
    Typed
