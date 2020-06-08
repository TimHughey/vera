defmodule Irrigation do
  @moduledoc """
    Irrigation Implementation for Wiss Landing
  """

  require Logger

  def front_porch(sw_name \\ "irrigation front porch", opts \\ [seconds: 30])
      when is_binary(sw_name) and is_list(opts) do
    duration_ms = TimeSupport.duration_ms(opts)

    task =
      Task.start(fn ->
        power(:on)
        Process.sleep(5000)

        [
          "starting \"",
          sw_name,
          "\" for ",
          inspect(duration_ms / 1000),
          "s"
        ]
        |> IO.iodata_to_binary()
        |> Logger.info()

        Switch.on(sw_name)

        Process.sleep(duration_ms)

        Switch.toggle(sw_name)

        power(:off)

        # time for switch commands to be acked
        Process.sleep(1000)

        [
          "completed \"",
          sw_name,
          "\" power=",
          power(:as_binary),
          " switch=",
          inspect(Switch.position(sw_name))
        ]
        |> IO.iodata_to_binary()
        |> Logger.info()
      end)

    task
  end

  def init do
    for n <- Switch.alias_names_begin_with("irrigation"), do: Switch.off(n)

    :ok
  end

  def power(atom \\ :toggle) when atom in [:on, :off, :toggle, :as_binary] do
    sw = "irrigation 12v power"

    case atom do
      :on ->
        Switch.on(sw)

      :off ->
        Switch.off(sw)

      :toggle ->
        Switch.toggle(sw)

      :as_binary ->
        inspect(Switch.position(sw))
    end
  end
end
