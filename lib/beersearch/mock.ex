defmodule Slacktapped.BeerSearch.Mock do
  @doc """
  Returns a mock response for the BeerSearch integration.

  ## Example

      iex> Slacktapped.BeerSearch.Mock.search("dogfish 60")
      [%{abv: "6% ABV", brewery: "Dogfish Head Craft Brewery", brewery_url: "http://path/to/brewery", ibu: "60 IBU",
         image: "https://untappd.akamaized.net/site/beer_logos/beer-3952_a5c9d_sm.jpeg",
         name: "60 Minute IPA", rating: "3.898", style: "IPA - American",
         url: "https://untappd.com/beer/3952"},
       %{abv: "6% ABV", brewery: "Mike's Tallybrew", brewery_url: "http://path/to/brewery", ibu: "N/A IBU",
         image: "https://untappd.akamaized.net/site/beer_logos/beer-1131483_de29d_sm.jpeg",
         name: "DogFishSkull 60", rating: "0", style: "Homebrew  |  IPA - American",
         url: "https://untappd.com/beer/1131483"},
       %{abv: "6% ABV", brewery: "Rambling Ridge Brewery", brewery_url: "http://path/to/brewery", ibu: "60 IBU",
         image: "https://untappd.akamaized.net/site/assets/images/temp/badge-beer-default.png",
         name: "DogFish 60 Clone", rating: "0",
         style: "Homebrew  |  IPA - American",
         url: "https://untappd.com/beer/1296192"}]

  Also has a catch for an empty search result:

      iex> Slacktapped.BeerSearch.Mock.search("fdsafdsa")
      []

  """
  def search("dogfish 60") do
    [%{abv: "6% ABV", brewery: "Dogfish Head Craft Brewery", brewery_url: "http://path/to/brewery", ibu: "60 IBU",
       image: "https://untappd.akamaized.net/site/beer_logos/beer-3952_a5c9d_sm.jpeg",
       name: "60 Minute IPA", rating: "3.898", style: "IPA - American",
       url: "https://untappd.com/beer/3952"},
     %{abv: "6% ABV", brewery: "Mike's Tallybrew", brewery_url: "http://path/to/brewery", ibu: "N/A IBU",
       image: "https://untappd.akamaized.net/site/beer_logos/beer-1131483_de29d_sm.jpeg",
       name: "DogFishSkull 60", rating: "0", style: "Homebrew  |  IPA - American",
       url: "https://untappd.com/beer/1131483"},
     %{abv: "6% ABV", brewery: "Rambling Ridge Brewery", brewery_url: "http://path/to/brewery", ibu: "60 IBU",
       image: "https://untappd.akamaized.net/site/assets/images/temp/badge-beer-default.png",
       name: "DogFish 60 Clone", rating: "0",
       style: "Homebrew  |  IPA - American",
       url: "https://untappd.com/beer/1296192"}]
  end
  def search("fdsafdsa") do
    []
  end
end
