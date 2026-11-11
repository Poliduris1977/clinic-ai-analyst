// Читает CSV из папки выбранного набора данных (pDataset) и поднимает заголовки.
// Кодировка 65001 = UTF-8 (в файлах есть BOM, Power Query его снимает).
(fileName as text) as table =>
let
    Path = pDataFolder & "\" & pDataset & "\" & fileName,
    Source = Csv.Document(File.Contents(Path), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars = true])
in
    Promoted
