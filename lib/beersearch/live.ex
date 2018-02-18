defmodule Slacktapped.BeerSearch.Live do
  @doc """
  Runs the provided query through the BeerSearch module.

  ## Example

      iex> Slacktapped.BeerSearch.Live.search("dogfish 90")
      [%{abv: "9% ABV", brewery: "Dogfish Head Craft Brewery",
         brewery_url: "https://untappd.com/w/dogfish-head-craft-brewery/459",
         ibu: "90 IBU",
         image: "https://untappd.akamaized.net/site/beer_logos/beer-8056_948fa_sm.jpeg",
         name: "90 Minute IPA", rating: "4.103", style: "IPA - Imperial / Double",
         url: "https://untappd.com/beer/8056"},
       %{abv: "9% ABV", brewery: "Dogfish Head Craft Brewery",
         brewery_url: "https://untappd.com/w/dogfish-head-craft-brewery/459",
         ibu: "N/A IBU",
         image: "https://untappd.akamaized.net/site/assets/images/temp/badge-beer-default.png",
         name: "90 Minute 30 Days", rating: "4.051", style: "IPA - Imperial / Double",
         url: "https://untappd.com/beer/1077892"}]

  """
  def search(query) do
    BeerSearch.search(query)
  end
end
