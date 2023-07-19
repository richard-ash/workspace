defmodule B2Web.Live.Game.WordsSoFar do
  use B2Web, :live_component

  @states %{
    :initializing => "Type or click a letter to start",
    :good_guess => "Good Guess",
    :bad_guess => "Bad Guess",
    :won => "Yay, you won!",
    :lost => "Sorry, you lost",
    :already_guessed => "You already guessed that letter"
  }

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="game-state">
        <%= state_name(@tally.game_state) %>
      </div>
      <div class="letters">
      <%= for letter <- @tally.letters do %>
      <% cls = if letter != "_", do: "letter correct", else: "letter" %>
        <div class={cls}>
          <%= letter %>
        </div>
      <% end %>
      </div>
    </div>
    """
  end

  defp state_name(state) do
    @states[state] || "Unknown"
  end
end
