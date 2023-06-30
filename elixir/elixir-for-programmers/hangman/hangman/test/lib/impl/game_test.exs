defmodule Hangman.Impl.GameTest do
  use ExUnit.Case
  alias Hangman.Impl.Game

  test "new game returns structure" do
    game = Game.new_game()

    assert game.letters |> length() > 0
    assert game.turns_left == 7
    assert game.game_state == :initializing
    assert game.used == MapSet.new()
  end

  test "new game returns correct word" do
    game = Game.new_game("wombat")

    assert game.letters |> length() > 0
    assert game.turns_left == 7
    assert game.game_state == :initializing
    assert game.letters == ["w", "o", "m", "b", "a", "t"]
  end

  test "state doesn't change if game is won or lost" do
    for state <- [:won, :lost] do
      game = Game.new_game()
      game = Map.put(game, :game_state, state)
      {_, tally} = Game.make_move(game, "w")

      assert tally.game_state == state
    end
  end

  test "we record letters we use" do
    game = Game.new_game()
    {game, _} = Game.make_move(game, "w")
    {game, _} = Game.make_move(game, "x")
    {game, _} = Game.make_move(game, "y")

    assert MapSet.equal?(game.used, MapSet.new(["w", "x", "y"]))
  end

  test "we recognize a letter in the word" do
    game = Game.new_game("wombat")
    {_game, tally} = Game.make_move(game, "w")

    assert tally.game_state == :good_guess
  end

  test "we recognize a letter not in the word" do
    game = Game.new_game("wombat")
    {_game, tally} = Game.make_move(game, "x")

    assert tally.game_state == :bad_guess
  end

  # hello
  test "can handle a sequence of moves" do
    [
      # guess | state     | turns_left | letters                 | used
      ["a", :bad_guess,       6,      ["_", "_", "_", "_", "_"], [ "a" ]],
      ["a", :already_guessed, 6,      ["_", "_", "_", "_", "_"], [ "a" ]],
      ["e", :good_guess,      6,      ["_", "e", "_", "_", "_"], [ "a" , "e" ]],
      ["x", :bad_guess,       5,      ["_", "e", "_", "_", "_"], [ "a" , "e", "x" ]],
    ]
    |> test_sequence_of_moves("hello")
  end

  test "can handle a winning game" do
    [
      # guess | state     | turns_left | letters                 | used
      ["a", :bad_guess,       6,      ["_", "_", "_", "_", "_"], [ "a" ]],
      ["a", :already_guessed, 6,      ["_", "_", "_", "_", "_"], [ "a" ]],
      ["e", :good_guess,      6,      ["_", "e", "_", "_", "_"], [ "a" , "e" ]],
      ["x", :bad_guess,       5,      ["_", "e", "_", "_", "_"], [ "a" , "e", "x" ]],
      ["l", :good_guess,      5,      ["_", "e", "l", "l", "_"], [ "a" , "e", "l", "x" ]],
      ["h", :good_guess,      5,      ["h", "e", "l", "l", "_"], [ "a" , "e", "h", "l", "x" ]],
      ["o", :won,             5,      ["h", "e", "l", "l", "o"], [ "a" , "e", "h", "l", "o", "x" ]],
    ]
    |> test_sequence_of_moves("hello")
  end

    test "can handle a losing game" do
    [
      # guess | state     | turns_left | letters                 | used
      ["a", :bad_guess,       6,      ["_", "_", "_", "_", "_"], [ "a" ]],
      ["a", :already_guessed, 6,      ["_", "_", "_", "_", "_"], [ "a" ]],
      ["e", :good_guess,      6,      ["_", "e", "_", "_", "_"], [ "a", "e" ]],
      ["x", :bad_guess,       5,      ["_", "e", "_", "_", "_"], [ "a", "e", "x" ]],
      ["m", :bad_guess,       4,      ["_", "e", "_", "_", "_"], [ "a", "e", "m", "x" ]],
      ["n", :bad_guess,       3,      ["_", "e", "_", "_", "_"], [ "a", "e", "m", "n", "x" ]],
      ["o", :good_guess,      3,      ["_", "e", "_", "_", "o"], [ "a", "e", "m", "n", "o", "x" ]],
      ["t", :bad_guess,       2,      ["_", "e", "_", "_", "o"], [ "a", "e", "m", "n", "o", "t", "x" ]],
      ["b", :bad_guess,       1,      ["_", "e", "_", "_", "o"], [ "a", "b", "e", "m", "n", "o", "t", "x" ]],
      ["c", :lost,            0,      ["h", "e", "l", "l", "o"], [ "a", "b", "c", "e", "m", "n", "o", "t", "x" ]],
    ]
    |> test_sequence_of_moves("hello")
  end

  def test_sequence_of_moves(script, word) do
    script
    |> Enum.reduce(Game.new_game(word), &check_one_move/2)
  end

  defp check_one_move([guess, state, turns_left, letters, used], game) do
    {game, tally} = Game.make_move(game, guess)

    assert tally.game_state == state
    assert tally.turns_left == turns_left
    assert tally.letters    == letters
    assert tally.used       == used

    game
  end
end
