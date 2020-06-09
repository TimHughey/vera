defmodule Reef.Salt.Fill do
  @moduledoc """
    Implements the aspects of mixing a batch of salt water
  """

  use Timex
  use Task
  require Logger

  @keeper_key_pid :reef_salt_mix_pid

  def abort do
    pid = Keeper.get_key(@keeper_key_pid)

    if Process.alive?(pid) do
      ["salt mix fill aborting (", inspect(pid), ")"] |> Logger.info()
      Task.Supervisor.terminate_child(Helen.TaskSupervisor, pid)
    else
      :not_alive
    end
  end

  def default_opts do
    [
      keeper_key: :reef_salt_mix,
      valve: "reefmix_rodi_valve",
      fill_primary_total_time: [hours: 8],
      fill_final_total_time: [hours: 1],
      fill_valve_open: [minutes: 2, seconds: 48],
      fill_valve_closed: [minutes: 17]
    ]
  end

  def kickstart(opts \\ []) when is_list(opts) do
    {_rc, task} = Task.Supervisor.start_child(Helen.TaskSupervisor, Reef.Salt.Fill, :run, [opts])

    Keeper.put_key(@keeper_key_pid, task)
  end

  @doc """
   Runs a task to fill the Salt Water Mix Tank
  """

  @doc since: "0.0.7"
  def run(opts \\ []) when is_list(opts) do
    opts_map = Keyword.merge(default_opts(), opts) |> Enum.into(%{})

    with %{keeper_key: key} = cm <- make_control_map(opts_map) do
      rc = [fill_primary(cm), fill_final(cm)]

      Keeper.put_key(key, rc)
    else
      error -> error
    end
  end

  ##
  ## Private
  ##

  defp fill_primary(%{fill_primary_start: s, fill_primary_duration: d} = cm) do
    ms = TimeSupport.duration_ms(d)
    elapsed = Duration.elapsed(now(), s)
    elapsed_ms = Duration.to_milliseconds(elapsed)

    # update the cycle count
    %{cycles: cys} = cm = Map.update(cm, :cycles, 1, fn x -> x + 1 end)

    [
      "salt mix fill starting cycle #",
      Integer.to_string(cys),
      " (elapsed time ",
      TimeSupport.humanize_duration(elapsed),
      ")"
    ]
    |> IO.iodata_to_binary()
    |> Logger.info()

    case elapsed_ms do
      # we have yet to pass the requesed runtime, do another cycle
      x when x < ms ->
        # add water to the salt water mix tank
        water_add(cm)

        # recharge the rodi tank
        water_recharge(cm)

        # call ourselves for another cycle
        fill_primary(cm)

      # enough time has elapsed, we're done
      _done ->
        [fill_primary: :done]
    end
  end

  defp fill_final(%{fill_final_duration: duration} = cm) do
    ms = TimeSupport.duration_ms(duration)

    # fill part 2 (final fill) is trivial -- just open the rodi valve to
    # the saltwater mix tank for the duration requested
    rodi_valve(cm, :open)
    Process.sleep(ms)
    rodi_valve(cm, :closed)

    [fill_final: :done]
  end

  defp make_control_map(opts_map) do
    validate = fn
      %{fill_primary_duration: _, fill_final_duration: _, fill_primary_start: _} = x -> x
      _not_valid -> %{}
    end

    # build the base control map with the passed opts and :started
    base = %{fill_primary_start: now()}
    control_map = Map.merge(base, opts_map)

    # convert the :fill and :final opts to durations
    for {key, val} <- control_map, into: %{} do
      case key do
        :fill_primary_total_time -> {:fill_primary_duration, TimeSupport.duration(val)}
        :fill_final_total_time -> {:fill_final_duration, TimeSupport.duration(val)}
        key -> {key, val}
      end
    end
    |> validate.()
  end

  defp now, do: Duration.now()

  defp rodi_valve(%{valve: valve}, pos) when pos in [:open, :closed] do
    case pos do
      :open -> Switch.on(valve)
      :closed -> Switch.off(valve)
    end

    Process.sleep(1000)

    Switch.position(valve)
  end

  defp water_add(%{fill_valve_open: opts} = cm) do
    ms = TimeSupport.duration_ms(opts)

    # open the valve to the salt water mix tank
    rodi_valve(cm, :open)

    # allow time to pass
    Process.sleep(ms)

    # close the valve to the salt water mix tank
    rodi_valve(cm, :closed)
  end

  defp water_recharge(%{fill_valve_closed: opts} = cm) do
    ms = TimeSupport.duration_ms(opts)

    # for safety sake, ensure the valve is OFF
    rodi_valve(cm, :closed)

    # to recharge the rodi tank just let time pass
    Process.sleep(ms)
  end
end
