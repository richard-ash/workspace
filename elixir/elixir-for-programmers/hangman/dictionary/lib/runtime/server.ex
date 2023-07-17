defmodule Dictionary.Runtime.Server do

  @type t :: pid()

  use Agent
  alias Dictionary.Impl.WordList

  def start_link(_args) do
    Agent.start_link(&WordList.word_list/0, name: __MODULE__)
  end

  def random_word() do
    Agent.get(__MODULE__, &(WordList.random_word/1))
  end
end
