defmodule Roost do
  @moduledoc false

  @compile {:no_warn_undefined, PulseWidth}

  alias PulseWidth
  use Timex

  def open do
    PulseWidth.duty_names_begin_with("roost lights", duty: 8191)
    PulseWidth.duty_names_begin_with("roost el wire entry", duty: 8191)

    PulseWidth.duty("roost el wire", duty: 4096)
    PulseWidth.duty("roost led forest", duty: 200)

    IO.write("spinning up disco ball.")
    PulseWidth.duty("roost")
    PulseWidth.duty("roost disco ball", duty: 5000)

    for _i <- 1..10 do
      Process.sleep(500)
      IO.write(".")
    end

    IO.puts(" done.")
    PulseWidth.duty("roost disco ball", duty: 4500)
    :ok
  end

  def closing(sleep_opts \\ [minutes: 5]) when is_list(sleep_opts) do
    PulseWidth.duty_names_begin_with("roost lights", duty: 0)
    PulseWidth.off("roost el wire")
    PulseWidth.off("roost disco ball")

    PulseWidth.duty("roost led forest", duty: 8191)
    PulseWidth.duty("roost el wire entry", duty: 8191)

    PulseWidth.duty_names_begin_with("front", duty: 0.03)

    Task.async(fn ->
      duration_ms(sleep_opts)
      |> Process.sleep()

      shutdown()
    end)
  end

  def shutdown do
    PulseWidth.off("roost disco ball")
    PulseWidth.duty_names_begin_with("roost lights", duty: 0)
    PulseWidth.duty_names_begin_with("roost el wire", duty: 0)

    PulseWidth.duty("roost led forest", duty: 0.02)
    PulseWidth.duty_names_begin_with("front", duty: 0.03)
  end

  defp duration(opts) when is_list(opts) do
    # after hours of searching and not finding an existing capabiility
    # in Timex we'll roll our own consisting of multiple Timex functions.
    ~U[0000-01-01 00:00:00Z]
    |> Timex.shift(Keyword.take(opts, valid_duration_opts()))
    |> Timex.to_gregorian_microseconds()
    |> Duration.from_microseconds()
  end

  defp duration(_anything), do: 0

  defp duration_ms(opts) when is_list(opts),
    do: duration(opts) |> Duration.to_milliseconds(truncate: true)

  defp valid_duration_opts,
    do: [
      :microseconds,
      :seconds,
      :minutes,
      :hours,
      :days,
      :weeks,
      :months,
      :years
    ]
end
