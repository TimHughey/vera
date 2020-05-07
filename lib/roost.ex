defmodule Roost do
  @moduledoc false

  def args_test(args) do
    {func, args} = List.pop_at(args, 0)

    combined = [func, args]

    inspect(combined, pretty: true) |> IO.puts()
  end

  def engage do
    on_list = [
      "roost lights sound one",
      "roost lights sound three",
      "roost el wire entry"
    ]

    for l <- on_list, do: pulse_width([:on, l])

    pulse_width([:duty, "roost el wire", [duty: 4096]])

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

  def shutdown do
    roost = pulse_width([:like, "roost "])

    for r <- roost, do: pulse_width([:off, r])
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
