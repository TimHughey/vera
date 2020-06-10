defmodule Reef.Salt.Prep do
  @moduledoc """
    Implements the aspects of preparing a recently filled Salt Water Mix Tank
    for salt mix
  """

  use Timex
  use Task
  require Logger

  @keeper_key_air_pid :reef_salt_prep_air_pid
  @keeper_key_pump_pid :reef_salt_prep_pump_pid

  def abort(opts \\ []) when is_list(opts) do
    opts_map = Map.merge(Enum.into(opts, %{}), Enum.into(%{}, default_opts()))

    air = {:air, Keeper.get_key(@keeper_key_air_pid), Map.get(opts_map, :switch_air)}
    pump = {:pump, Keeper.get_key(@keeper_key_pump_pid), Map.get(opts_map, :switch_pump)}

    for {subsystem, pid, sw_name} <- [air, pump] do
      if Process.alive?(pid) do
        ["salt mix prep aborting ", inspect(subsystem), " ", inspect(pid)] |> Logger.info()
        Task.Supervisor.terminate_child(Helen.TaskSupervisor, pid)
        rc = Switch.off(sw_name, wait_for_pid: pid, timeout_ms: 1500)
        {:aborted, subsystem, sw_name, rc}
      else
        {:not_alive, subsystem, nil, nil}
      end
    end
  end

  def default_opts do
    [
      air_keeper_key: @keeper_key_air_pid,
      pump_keeper_key: @keeper_key_pump_pid,
      switch_air: "mixtank_air",
      switch_pump: "mixtank_pump",
      prep_total_time: [hours: 12],
      air_on: [minutes: 15],
      air_off: [minutes: 5],
      pump_on: [minutes: 5],
      pump_off: [minutes: 30]
    ]
  end

  def kickstart(opts \\ []) when is_list(opts) do
    {_rc, pid} =
      Task.Supervisor.start_child(
        Helen.TaskSupervisor,
        Reef.Salt.Prep,
        :run,
        [Keyword.put(opts, :subsystem, :air)]
      )

    Keeper.put_key(@keeper_key_air_pid, pid)

    {_rc, pid} =
      Task.Supervisor.start_child(
        Helen.TaskSupervisor,
        Reef.Salt.Prep,
        :run,
        [Keyword.put(opts, :subsystem, :pump)]
      )

    Keeper.put_key(@keeper_key_pump_pid, pid)
  end

  @doc """
   Runs the Salt Mix Prep task identified by the key :subsystem in opts
  """

  @doc since: "0.0.23"
  def run(opts \\ []) when is_list(opts) do
    opts_map = Keyword.merge(default_opts(), opts) |> Enum.into(%{})

    with %{keeper_key: key} = cm <- make_control_map(opts_map) do
      rc = run_subsystem(cm)

      Keeper.put_key(key, rc)
    else
      error -> error
    end
  end

  ##
  ## Private
  ##

  defp run_subsystem(%{subsystem: subsystem, subsystem_start: s, prep_duration: d} = cm) do
    max_ms = TimeSupport.duration_ms(d)
    elapsed = Duration.elapsed(now(), s)

    # update the cycle count
    %{cycles: cys} = cm = Map.update(cm, :cycles, 1, fn x -> x + 1 end)

    [
      "salt mix prep \"",
      Atom.to_string(subsystem),
      "\" starting cycle #",
      Integer.to_string(cys),
      " (elapsed time ",
      TimeSupport.humanize_duration(elapsed),
      ")"
    ]
    |> IO.iodata_to_binary()
    |> Logger.info()

    case Duration.to_milliseconds(elapsed) do
      # we have yet to pass the requesed runtime, do another cycle
      x when x < max_ms ->
        # turn on, off and sleep the subsystem
        subsystem(cm)

        # call ourselves for another cycle
        run_subsystem(cm)

      _done ->
        # enough time has elapsed, we're done
        Keyword.new() |> Keyword.put(subsystem, :done)
    end
  end

  defp make_control_map(%{subsystem: subsystem} = opts_map) do
    validate = fn
      %{prep_duration: _, on: _, off: _, switch: _, keeper_key: _} = x ->
        x

      not_valid ->
        ["invalid control map ", inspect(not_valid, pretty: true)] |> IO.puts()
        %{}
    end

    add_keeper_key = fn
      %{air_keeper_key: air_key, pump_keeper_key: pump_key, subsystem: sub} = cm ->
        case sub do
          :air -> Map.put(cm, :keeper_key, air_key)
          :pump -> Map.put(cm, :keeper_key, pump_key)
          true -> Map.put(cm, :no_match, sub)
        end
    end

    # build the base control map with the passed opts and :started
    base = %{subsystem_start: now()}
    control_map = Map.merge(base, opts_map)

    # convert the :fill and :final opts to durations
    for {key, val} <- control_map, into: %{} do
      cond do
        key == :prep_total_time -> {:prep_duration, TimeSupport.duration(val)}
        subsystem == :air and key == :air_on -> {:on, TimeSupport.duration(val)}
        subsystem == :air and key == :air_off -> {:off, TimeSupport.duration(val)}
        subsystem == :air and key == :switch_air -> {:switch, val}
        subsystem == :pump and key == :pump_on -> {:on, TimeSupport.duration(val)}
        subsystem == :pump and key == :pump_off -> {:off, TimeSupport.duration(val)}
        subsystem == :pump and key == :switch_pump -> {:switch, val}
        true -> {key, val}
      end
    end
    |> add_keeper_key.()
    |> validate.()
  end

  defp now, do: Duration.now()

  defp subsystem(%{switch: sw_name, on: on, off: off}) do
    on_ms = TimeSupport.duration_ms(on)
    off_ms = TimeSupport.duration_ms(off)

    Switch.on(sw_name)
    Process.sleep(on_ms)

    Switch.off(sw_name)
    Process.sleep(off_ms)
  end
end
