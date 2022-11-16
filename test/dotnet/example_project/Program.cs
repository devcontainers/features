// See https://aka.ms/new-console-template for more information

using Newtonsoft.Json;

Console.WriteLine("Hello, World!");

string json = @"{
  'Name': 'Inception',
  'ReleaseDate': '2010-07-08T00:00:00',
  'Genres': [
    'Action',
    'Thriller'
  ]
}";

Movie? m = JsonConvert.DeserializeObject<Movie>(json);

if (m == default)
{
    Console.WriteLine("Decoding failed!");
}
else
{
    Console.WriteLine($"Name: {m.Name}");
    Console.WriteLine($"Release Date: {m.ReleaseDate}");
    Console.WriteLine($"Genres: {string.Join(", ", m.Genres)}");
}
