defmodule HtmlClientWeb.HangmanHTML do
  use HtmlClientWeb, :html
  use HtmlClientWeb, :verified_routes

  embed_templates "hangman_html/*"


  @status_fields %{
    initializing: { "initializing", "Guess the word, one letter at a time" },
    good_guess: {"good-guess", "Good guess!"},
    bad_guess: {"bad-guess", "Bad guess!"},
    won: {"won", "You won!"},
    lost: {"lost", "You lost!"},
    already_guessed: {"already-guessed", "You already guessed that letter"},
  }

  def home do
    ~p"/hangman"
  end

  def move_status(status) do
    { class, msg } = @status_fields[status]
    "<div class='status #{class}'>#{msg}</div>"
  end

  def continue_or_try_again(_conn, status) when status in [:won, :lost] do
    button("New game", to: home(), method: :post)
  end

  def continue_or_try_again(conn, _) do
    form_for(conn, home(), [ as: "make_move", method: :put ], fn f ->
      [
        text_input(f, :guess),
        " ",
        submit("Make a guess")
      ]
    end)
  end

  def figure_for(0) do
    ~s"""
      -----
      |   |
      |   |
      |   O
      |  /|\\
      |  / \\
      |
      |
      _________
    """
  end

  def figure_for(1) do
    ~s"""
      -----
      |   |
      |   |
      |   O
      |  /|\\
      |  /
      |
      |
      _________
    """
  end

  def figure_for(2) do
    ~s"""
      -----
      |   |
      |   |
      |   O
      |  /|\\
      |
      |
      |
      _________
    """
  end

  def figure_for(3) do
    ~s"""
      -----
      |   |
      |   |
      |   O
      |  /|
      |
      |
      |
      _________
    """
  end

  def figure_for(4) do
    ~s"""
      -----
      |   |
      |   |
      |   O
      |   |
      |
      |
      |
      _________
    """
  end

  def figure_for(5) do
    ~s"""
      -----
      |   |
      |   |
      |   O
      |
      |
      |
      |
      _________
    """
  end

  def figure_for(6) do
    ~s"""
      -----
      |   |
      |   |
      |
      |
      |
      |
      |
      _________
    """
  end

  def figure_for(7) do
    ~s"""
      -----
      |
      |
      |
      |
      |
      |
      |
      _________
    """
  end
end
