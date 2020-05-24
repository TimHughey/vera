defmodule Roost do
  @moduledoc false

  def args_test(args) do
    {func, args} = List.pop_at(args, 0)

    combined = [func, args]

    inspect(combined, pretty: true) |> IO.puts()
  end

  def engage do
    pulse_width([:duty_names_begin_with, "roost lights", [duty: 8191]])
    pulse_width([:duty_names_begin_with, "roost el wire entry", [duty: 8191]])

    pulse_width([:duty, "roost el wire", [duty: 4096]])
    pulse_width([:duty, "roost led forest", [duty: 200]])

    IO.write("spinning up disco ball.")
    pulse_width([:duty, "roost disco ball", [duty: 5000]])

    for _i <- 1..10 do
      Process.sleep(500)
      IO.write(".")
    end

    IO.puts(" done.")
    pulse_width([:duty, "roost disco ball", [duty: 4500]])
    :ok
  end

  def closing(sleep_opts \\ [minutes: 15]) when is_list(sleep_opts) do
    import TimeSupport, only: [duration_ms: 1]

    pulse_width([:duty_names_begin_with, "roost lights", [duty: 0]])
    pulse_width([:off, "roost el wire"])
    pulse_width([:off, "roost disco ball"])

    pulse_width([:duty, "roost led forest", [duty: 8191]])
    pulse_width([:duty, "roost el wire entry", [duty: 8191]])

    pulse_width([:duty_names_begin_with, "front", [duty: 0.03]])

    Task.async(fn ->
      Process.sleep(duration_ms(sleep_opts))
      closed()
    end)
  end

  def closed do
    pulse_width([:off, "roost disco ball"])
    pulse_width([:duty_names_begin_with, "roost lights", [duty: 0]])
    pulse_width([:duty_names_begin_with, "roost el wire", [duty: 0]])

    pulse_width([:duty, "roost led forest", [duty: 0.02]])
    pulse_width([:duty_names_begin_with, "front", [duty: 0.03]])
  end

  defp pulse_width(args) do
    {func, args} = List.pop_at(args, 0)

    host = rpc_host()

    if is_nil(host) do
      IO.puts("missing rpc host")
      {:missing_rpc_host}
    else
      :rpc.call(host, PulseWidth, func, args)
    end
  end

  defp rpc_host, do: Application.get_env(:vera, :rpc_host)
end
