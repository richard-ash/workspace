defmodule HtmlClientWeb.CustomComponents do
  use Phoenix.Component

  attr :tally, :map, required: true
  def tally_info(assigns) do
    ~H"""
    <table class="tally">
      <tr>
        <th>Turns left:</th>
        <td><%= @tally.turns_left %></td>
      </tr>
      <tr>
        <th>Letters used:</th>
        <td><%= @tally.used |> Enum.join(", ") %></td>
      </tr>
      <tr>
        <th>Word so far:</th>
        <td><%= @tally.letters |> Enum.join(" ") %></td>
      </tr>
    </table>
    """
  end
end