// Визиты ERP. Типы заданы явно, автоопределение типов не используется.
let
    Source = fnReadCsv("visits.csv"),
    Typed = Table.TransformColumnTypes(Source, {
        {"visit_id", type text}, {"patient_id", type text}, {"doctor_id", type text},
        {"clinic_id", type text}, {"direction_code", type text},
        {"visit_date", type date}, {"visit_time", type text}, {"status", type text}
    }, "en-US"),
    // пустой doctor_id приходит как "" — превращаем в null
    NoDoctorNull = Table.TransformColumns(Typed, {{"doctor_id", each if _ = "" then null else _, type nullable text}})
in
    NoDoctorNull
