// Позиции услуг ERP.
let
    Source = fnReadCsv("visit_items.csv"),
    Typed = Table.TransformColumnTypes(Source, {
        {"item_id", type text}, {"visit_id", type text}, {"service_id", type text},
        {"qty", Int64.Type}, {"list_price_at_date", type number},
        {"discount_pct", type number}, {"price_fact", type number}, {"revenue", type number}
    }, "en-US")
in
    Typed
