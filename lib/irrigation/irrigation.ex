defmodule Irrigation do
  @moduledoc """
    Irrigation Implementation for Wiss Landing
  """

  require Logger

  def front_porch(sw_name \\ "irrigation front porch", opts \\ [seconds: 30])
      when is_binary(sw_name) and is_list(opts) do
    irrigate(sw_name, opts)
  end

  def garden_quick(sw_name \\ "irrigation garden", opts \\ [minutes: 1])
      when is_binary(sw_name) and is_list(opts) do
    irrigate(sw_name, opts)
  end

  def garden(sw_name \\ "irrigation garden", opts \\ [minutes: 30])
      when is_binary(sw_name) and is_list(opts) do
    irrigate(sw_name, opts)
  end

  def irrigate(sw_name, opts) when is_binary(sw_name) and is_list(opts) do
    duration = TimeSupport.duration(opts)
    ms = TimeSupport.duration_ms(opts)

    task =
      Task.start(fn ->
        power(:on)
        Process.sleep(5000)

        [
          "\"",
          sw_name,
          "\" starting for ",
          TimeSupport.humanize_duration(duration)
        ]
        |> IO.iodata_to_binary()
        |> Logger.info()

        Switch.on(sw_name)

        Process.sleep(ms)

        Switch.toggle(sw_name)

        power(:off)

        # time for switch commands to be acked
        Process.sleep(1000)

        [
          "\"",
          sw_name,
          "\" finished power=",
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
    for n <- Switch.names_begin_with("irrigation"), do: Switch.off(n)

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
