defmodule Irrigation do
  @moduledoc """
    Irrigation Implementation for Wiss Landing
  """
  use Timex
  import Crontab.CronExpression

  def flower_boxes(opts \\ [seconds: 45]) when is_list(opts) do
    irrigate("irrigation flower boxes", opts)
  end

  def garden_quick(opts \\ [minutes: 1]) when is_list(opts) do
    irrigate("irrigation garden", opts)
  end

  def garden(opts \\ [minutes: 30]) when is_list(opts) do
    irrigate("irrigation garden", opts)
  end

  def irrigate(sw_name, opts) when is_binary(sw_name) and is_list(opts) do
    opts = List.flatten(opts)
    duration = TimeSupport.duration(opts)
    ms = TimeSupport.duration_ms(opts)

    task =
      Task.start(fn ->
        power(:on)
        Process.sleep(5000)

        ts = Timex.local() |> Timex.format!("{YYYY}-{0M}-{D} {h24}:{m}")

        """
        #{ts} starting #{sw_name} for #{TimeSupport.humanize_duration(duration)}
        """
        |> log()

        Switch.on(sw_name)

        Process.sleep(ms)

        Switch.toggle(sw_name)

        power(:off)

        # time for switch commands to be acked
        Process.sleep(3000)

        ts = Timex.local() |> Timex.format!("{YYYY}-{0M}-{D} {h24}:{m}")

        """
        #{ts} finished #{sw_name} power=#{power(:as_binary)} switch=#{
          inspect(Switch.position(sw_name))
        }
        """
        |> log()
      end)

    task
  end

  def init(opts \\ []) when is_list(opts) do
    switches = (opts ++ ["irrigation"]) |> List.flatten()
    for n <- switches, do: Switch.off(n)

    schedule(:flower_boxes_am, ~e[0 7 * * *], &flower_boxes/1)
    schedule(:flower_boxes_noon, ~e[0 12 * * *], &flower_boxes/1, seconds: 15)
    schedule(:flower_boxes_pm, ~e[20 16 * * *], &flower_boxes/1, seconds: 15)

    Keeper.put_key(:irrigate, "")

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

  def schedule(name, crontab, func, opts \\ []) do
    Helen.Scheduler.delete_job(name)

    Helen.Scheduler.new_job()
    |> Quantum.Job.set_name(name)
    |> Quantum.Job.set_schedule(crontab)
    |> Quantum.Job.set_task(fn -> func.(opts) end)
    |> Helen.Scheduler.add_job()
  end

  def status do
    log = Keeper.get_key(:irrigate)

    IO.puts(log)
  end

  defp log(msg) do
    log = Keeper.get_key(:irrigate)

    new_log = Enum.join([log, msg], "")

    Keeper.put_key(:irrigate, new_log)
  end
end
