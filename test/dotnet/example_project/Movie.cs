// See https://aka.ms/new-console-template for more information

internal class Movie
{
    public string Name { get; set; } = "Default Name";
    public DateTime ReleaseDate { get; set; }
    public List<string> Genres { get; set; } = new List<string>();
}
