defmodule Reef.Salt.Fill do
  @moduledoc """
    Implements the aspects of mixing a batch of salt water
  """

  use Timex
  require Logger

  @doc """
    Starts a task to fill the Salt Water Mix Tank
  """

  @doc since: "0.0.7"
  def fill(opts \\ [fill: [hours: 8], final: [hours: 1]]) when is_list(opts) do
    control_map = make_control_map(opts)

    task =
      Task.async(fn ->
        rc = [fill_part1(control_map), fill_part2(control_map)]

        Keeper.put_key(:reef_fill_salt_mix, rc)
      end)

    Keeper.put_key(:reef_fill_salt_mix, task)
  end

  ##
  ## Private
  ##

  defp fill_part1(%{fill_one_start: started, fill: fill_duration} = control) do
    duration_ms = TimeSupport.duration_ms(fill_duration)
    elapsed = Duration.elapsed(now(), started)
    elapsed_ms = Duration.to_milliseconds(elapsed)

    # update the cycle count
    %{cycles: cycles} = control = Map.update(control, :cycles, 1, fn x -> x + 1 end)

    [
      "salt mix fill starting cycle #",
      Integer.to_string(cycles),
      " (elapsed time ",
      TimeSupport.humanize_duration(elapsed),
      ")"
    ]
    |> IO.iodata_to_binary()
    |> Logger.info()

    case elapsed_ms do
      # we have yet to pass the requesed runtime, do another cycle
      x when x < duration_ms ->
        # add water to the salt water mix tank
        water_add()

        # recharge the rodi tank
        water_recharge()

        # call ourselves for another cycle
        fill_part1(control)

      # enough time has elapsed, we're done
      true ->
        [fill_part1: :done]
    end
  end

  defp fill_part2(%{final: final_duration}) do
    duration_ms = TimeSupport.duration_ms(final_duration)

    # fill part 2 (final fill) is trivial -- just open the rodi valve to
    # the saltwater mix tank for the duration requested
    rodi_valve(:open)
    Process.sleep(duration_ms)
    rodi_valve(:closed)

    [fill_part2: :done]
  end

  defp make_control_map(opts) do
    validate = fn
      %{fill: _, final: _} = x -> x
      _not_valid -> %{}
    end

    # build the base control map with the passed opts and :started
    base = %{fill_one_start: now(), all_opts: opts}
    control_map = Map.merge(base, Enum.into(opts, %{}))

    # convert the :fill and :final opts to durations
    for {key, val} <- control_map, into: %{} do
      case key do
        :fill -> {key, TimeSupport.duration(val)}
        :final -> {key, TimeSupport.duration(val)}
        key -> {key, val}
      end
    end
    |> validate.()
  end

  defp now, do: Duration.now()

  defp rodi_valve(sw_name \\ "reefmix_rodi_valve", pos)
       when is_binary(sw_name) and pos in [:open, :closed] do
    case pos do
      :open -> Switch.on(sw_name)
      :closed -> Switch.off(sw_name)
    end

    Process.sleep(1000)

    Switch.position(sw_name)
  end

  defp water_add(sw_name \\ "reefmix_rodi_valve", opts \\ [minutes: 2, seconds: 48]) do
    ms = TimeSupport.duration_ms(opts)

    # open the valve to the salt water mix tank
    rodi_valve(sw_name, :open)

    # allow time to pass
    Process.sleep(ms)

    # close the valve to the salt water mix tank
    rodi_valve(sw_name, :closed)
  end

  defp water_recharge(sw_name \\ "reefmix_rodi_valve", opts \\ [minutes: 17]) do
    ms = TimeSupport.duration_ms(opts)

    # for safety sake, ensure the valve is OFF
    rodi_valve(sw_name, :closed)

    # to recharge the rodi tank just let time pass
    Process.sleep(ms)
  end
end
