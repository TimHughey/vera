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

        # NOTE:  current relays are low activated!
        Switch.position(sw_name, position: false)

        Process.sleep(duration_ms)

        Switch.position(sw_name, position: true)

        power(:off)

        Process.sleep(500)

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

  def power(atom \\ :toggle) when atom in [:on, :off, :toggle, :as_binary] do
    sw = "irrigation 12v power"

    case atom do
      :on ->
        Switch.position(sw, position: true)

      :off ->
        Switch.position(sw, position: false)

      :toggle ->
        curr_pos = Switch.position(sw)
        Switch.position(sw, position: not curr_pos)

      :as_binary ->
        inspect(Switch.position(sw))
    end
  end
end
