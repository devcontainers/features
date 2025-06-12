using Newtonsoft.Json;

string json = """
{
  "Name": "Inception",
  "ReleaseDate": "2010-07-08T00:00:00",
  "Genres": [
    "Action",
    "Thriller"
  ]
}
""";

Movie? m = JsonConvert.DeserializeObject<Movie>(json);

if (m == default)
{
    Console.WriteLine("Decoding failed!");
}
else
{
    Console.WriteLine($"Movie name: {m.Name}");
    Console.WriteLine($"Release Date: {m.ReleaseDate}");
    Console.WriteLine($"Genres: {string.Join(", ", m.Genres)}");
}

class Movie(string? name, DateTime releaseDate, List<string>? genres)
{
    public string Name { get; set; } = name ?? "Default Name";
    public DateTime ReleaseDate { get; set; } = releaseDate;
    public List<string> Genres { get; set; } = genres ?? [];
}