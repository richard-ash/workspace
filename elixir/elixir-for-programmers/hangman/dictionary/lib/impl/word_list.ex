defmodule Dictionary.Impl.WordList do
  @type t :: list(String.t)

  @spec word_list :: t
  def word_list() do
    "../../assets/words.txt"
    |> Path.expand(__DIR__)
    |> File.read!()
    |> String.split("\n", trim: true)
  end

  @spec random_word(t) :: String.t
  def random_word(words) do
    words
    |> Enum.random()
  end
end
