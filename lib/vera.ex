defmodule Vera do
  @moduledoc """
  Vera controls the Roost and WissLanding outdoor lights.
  """

  @doc """
  Roost.

  ## Examples

      iex> Vera.hello()
      :world

  """
  def roost(:engage) do
    Roost.engage()
  end

  def roost(:shutdown) do
    Roost.shutdown()
  end
end
