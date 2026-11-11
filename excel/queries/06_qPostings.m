// Проводки 1С. Счета хранятся текстом.
let
    Source = fnReadCsv("postings_1c.csv"),
    Typed = Table.TransformColumnTypes(Source, {
        {"posting_id", type text}, {"date", type date}, {"clinic_id", type text},
        {"debit", type text}, {"credit", type text}, {"amount", type number},
        {"direction_code", type text}, {"counterparty", type text},
        {"doc_type", type text}, {"comment", type text}
    }, "en-US")
in
    Typed
