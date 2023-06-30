defmodule Hangman.Impl.Game do
  alias Hangman.Type
  @type t :: %__MODULE__{
    turns_left: integer,
    game_state: Type.state,
    letters: list(String.t),
    used: MapSet.t(String.t)
  }

  defstruct(
    turns_left: 7,
    game_state: :initializing,
    letters: [],
    used: MapSet.new()
  )

  @spec new_game :: t
  def new_game, do: Dictionary.random_word() |> new_game()

  @spec new_game(String.t) :: t
  def new_game(word) do
    %__MODULE__{
      letters: word |> String.codepoints(),
    }
  end

  @spec make_move(t, String.t) :: {t, Type.tally}
  def make_move(game = %{game_state: state}, _guess) when state in [:won, :lost], do: game |> return_with_tally()
  def make_move(game, guess) do
    game
    |> accept_guess(guess, MapSet.member?(game.used, guess))
    |> return_with_tally()
  end

  def tally(game) do
    %{
      turns_left: game.turns_left,
      game_state: game.game_state,
      letters: game |> reveal_guessed_letters(),
      used: game.used |> MapSet.to_list() |> Enum.sort()
    }
  end

  defp return_with_tally(game) do
    {game, tally(game)}
  end

  defp accept_guess(game, _guess, _already_used = true), do: %{game | game_state: :already_guessed}
  defp accept_guess(game, guess, _already_used) do
    %{game | used: MapSet.put(game.used, guess)}
    |> score_guess(Enum.member?(game.letters, guess))
  end

  # guess all letters -> :won | :good_guess
  defp score_guess(game, _good_guess = true) do
    MapSet.subset?(MapSet.new(game.letters), game.used)
    |> maybe_won()
    |> then(fn state -> %{game | game_state: state} end)
  end
  # turns left == 1 -> :lost | :bad_guess
  defp score_guess(game = %{ turns_left: 1 }, _bad_guess),  do: %{ game | game_state: :lost, turns_left: 0 }
  defp score_guess(game, _bad_guess),                       do: %{ game | turns_left: game.turns_left - 1, game_state: :bad_guess }

  defp maybe_won(true), do: :won
  defp maybe_won(_),    do: :good_guess

  defp reveal_guessed_letters(game = %{ game_state: :lost }), do: game.letters
  defp reveal_guessed_letters(game) do
    game.letters
    |> Enum.map(fn letter -> MapSet.member?(game.used, letter) |> maybe_reveal_letter(letter) end)
  end

  defp maybe_reveal_letter(true, letter), do: letter
  defp maybe_reveal_letter(_, _letter),   do: "_"
end
