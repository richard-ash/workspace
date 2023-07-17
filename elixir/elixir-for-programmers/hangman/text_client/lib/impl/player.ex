defmodule TextClient.Impl.Player do
  @typep game :: Hangman.game
  @typep tally :: Hangman.tally
  @typep state :: { game, tally }

  @spec start(game) :: :ok
  def start(game) do
    tally = Hangman.tally(game)
    interact({ game, tally })
  end

  @spec interact(state :: state) :: :ok
  def interact({ _game, tally = %{ game_state: :won }}) do
    IO.puts("Congratulations! You won! The word was #{tally.letters |> Enum.join()}.")
  end
  def interact({ _game, tally = %{ game_state: :lost }}) do
    IO.puts("Sorry you lost. The word was #{tally.letters |> Enum.join()}.")
  end

  def interact({ game, tally }) do
    # feedback
    IO.puts(feedback_for(tally))
    # display current word
    IO.puts(current_word(tally))

    # get next guess
    # make move
    tally = Hangman.make_move(game, get_guess())
    interact({ game, tally })
  end

  defp feedback_for(tally = %{ game_state: :initializing }) do
    "Welcome to Hangman! I'm thinking of a #{tally.letters |> length()} letter word."
  end

  defp feedback_for(_tally = %{ game_state: :good_guess }), do: "Good guess!"
  defp feedback_for(_tally = %{ game_state: :bad_guess }), do: "Bad guess!"
  defp feedback_for(_tally = %{ game_state: :already_guessed }), do: "You already guessed that!"

  defp current_word(tally) do
    [
      "Word so far: ", tally.letters |> Enum.join(),
      " Turns left: ", tally.turns_left |> to_string(),
      " Used so far: ", tally.used |> Enum.join(",")
    ]
  end

  defp get_guess() do
    IO.gets("Enter your guess: ")
    |> String.trim()
    |> String.downcase()
  end
end
