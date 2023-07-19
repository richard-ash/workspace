defmodule HtmlClientWeb.HangmanHTML do
  use HtmlClientWeb, :html
  use HtmlClientWeb, :verified_routes

  embed_templates "hangman_html/*"

  def home do
    ~p"/hangman"
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
