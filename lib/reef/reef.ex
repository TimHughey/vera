defmodule Reef do
  @moduledoc """
  Reef System Maintenance Command Line Interface
  """

  @compile {:no_warn_undefined, Thermostat.Server}
  @compile {:no_warn_undefined, Sensor}

  # import IO.ANSI

  # @doc """
  #   Set system for adding salt to the SWMT (salt water mix tank).
  #
  #     ## Dutycycle and Thermostats
  #
  #       The Dutycycles and Thermostats are set to the following modes:
  #
  #       Name          | Mode           | Type
  #       ------------- |--------------- --------------
  #        mix pump     |  add salt      |  Dutycycle
  #        mix air      |  add salt      |  Dutycycle
  #        rodi fill    |  __halted__    |  Dutycycle
  #        mix heat     |  standby       |  Thermostat
  #        display tank |  __unchanged__ |  Thermostat
  #
  # """
  # def add_salt do
  #   profile_name = "add salt"
  #   rmp() |> dc_activate_profile(profile_name)
  #   rma() |> dc_halt()
  #   rmrf() |> dc_halt()
  #   swmt() |> ths_activate(standby())
  # end
  #

  def init(
        opts \\ [switches: ["reefmix_rodi_valve", "mixtank_pump", "mixtank_air", "mixtank_heat"]]
      ) do
    switches = Keyword.get(opts, :switches, [])

    for s <- switches, do: Switch.off(s)
  end

  def aerate(opts \\ []), do: Reef.Salt.Prep.kickstart(opts)
  def halt_aerate(opts \\ []), do: Reef.Salt.Prep.abort(opts)

  def clean(mode \\ :toggle, sw_name \\ "display tank ato")
      when is_atom(mode) and mode in [:engage, :disengage, :toggle, :help, :usage] and
             is_binary(sw_name) do
    {:ok, pos} = Switch.position(sw_name)

    # NOTE:
    #  display tank ato is wired normally on.  to turn off ATO set the
    #  switch to on.

    cond do
      mode == :toggle and pos == true ->
        Switch.toggle(sw_name)
        ["\nclean mode DISENGAGED\n"] |> IO.puts()
        :ok

      mode == :toggle and pos == false ->
        Switch.toggle(sw_name)
        ["\nclean mode ENGAGED\n"] |> IO.puts() |> IO.puts()
        :ok

      mode == :engage ->
        Switch.on(sw_name, lazy: false)
        ["\nclean mode forced to ENGAGED\n"] |> IO.puts()
        :ok

      mode == :disengage ->
        Switch.off(sw_name, lazy: false)
        ["\nclean mode forced to DISENGAGED\n"] |> IO.puts()
        :ok

      mode ->
        [
          "\n",
          "Reef.clean/1: \n",
          " :toggle    - toogle clean mode (default)\n",
          " :engage    - engage clean mode with lazy: false\n",
          " :disengage - disengage clean mode with lazy: false\n"
        ]
        |> IO.puts()

        :ok
    end
  end

  def fill(opts \\ []), do: Reef.Salt.Fill.kickstart(opts)
  def halt_fill(opts \\ []), do: Reef.Salt.Fill.abort(opts)

  # def heat_standby do
  #   [
  #     {swmt(), swmt() |> ths_activate(standby())},
  #     {dt(), dt() |> ths_activate(standby())}
  #   ]
  # end
  #
  # def keep_fresh do
  #   dc_activate_profile(rmp(), "keep fresh")
  #   dc_activate_profile(rma(), "keep fresh")
  # end
  #
  # def heat(p) when is_binary(p), do: ths_activate(swmt(), p)
  #
  # def heat(_), do: print_usage("mix_heat", "profile")
  #
  # def match_display_tank do
  #   ths_activate(swmt(), "prep for change")
  #   dc_activate_profile(rma(), "salt mix")
  #   dc_activate_profile(rmp(), "salt mix")
  #   status()
  # end
  #

  # def status(opts \\ []) do
  #   opts = opts ++ [active: true]
  #
  #   Keyword.get(opts, :clear_screen, true) && IO.puts(clear())
  #   print_heading("Reef Subsystem Status")
  #
  #   dcs = for name <- [rmp(), rma(), rmrf(), ato()], do: dc_status(name, opts)
  #   ths = for name <- [swmt(), display_tank()], do: th_status(name, opts)
  #   ss = for name <- [dt_sensor(), swmt_sensor()], do: sensor_status(name)
  #
  #   all = dcs ++ ths
  #
  #   :ok =
  #     Scribe.print(all,
  #       data: [
  #         {"Subsystem", :subsystem},
  #         {"Status", :status},
  #         {"Active", :active}
  #       ]
  #     )
  #     |> IO.puts()
  #
  #   Scribe.print(ss,
  #     data: [{"Sensor", :subsystem}, {"Temperature", :status}]
  #   )
  #   |> IO.puts()
  # end

  # def halt("display tank ato"), do: dc_activate_profile(ato(), "off")
  # def halt(name) when is_binary(name), do: dc_halt(name)
  # def halt_ato, do: dc_activate_profile(ato(), "off")
  # def halt_air, do: dc_halt(rma())
  # def halt_display_tank, do: ths_standby(dt())
  # def halt_pump, do: dc_halt(rmp())
  # def halt_rodi, do: dc_halt(rmrf())

  # def resume("display tank ato"), do: dc_halt(ato())
  # def resume(name) when is_binary(name), do: dc_resume(name)
  # def resume_ato, do: dc_halt(ato())
  # def resume_air, do: dc_resume(rma())
  # def resume_display_tank, do: ths_activate(dt(), "75F")
  # def resume_pump, do: dc_resume(rmp())
  # def resume_rodi, do: dc_resume(rmrf())

  # def ths_activate(th, profile)
  #     when is_binary(th) and is_binary(profile) do
  #   Thermostat.Server.activate_profile(th, profile)
  # end
  #
  # def ths_standby(th) when is_binary(th) do
  #   Thermostat.Server.standby(th)
  # end
  #
  # def utility_pump(p) when is_binary(p),
  #   do: dc_activate_profile(rmp(), p)
  #
  # def utility_pump(_), do: print_usage("utility_pump", "profile")
  #
  # def utility_pump_off, do: rmp() |> dc_halt()
  #
  # def water_change_begin(opts \\ [check_diff: true, interactive: true])
  #
  # def water_change_begin(:help) do
  #   IO.puts(water_change_begin_help())
  # end
  #
  # def water_change_begin(opts) when is_list(opts) do
  #   check_diff = Keyword.get(opts, :check_diff, true)
  #   allowed_diff = Keyword.get(opts, :allowed_diff, 0.8)
  #   interactive = Keyword.get(opts, :interactive, true)
  #
  #   mixtank_temp = Sensor.fahrenheit(name: "mixtank", since_secs: 30)
  #
  #   display_temp = Sensor.fahrenhei(name: "display_tank", since_secs: 30)
  #
  #   temp_diff = abs(mixtank_temp - display_temp)
  #
  #   if temp_diff > allowed_diff and check_diff do
  #     if interactive do
  #       IO.puts("--> WARNING <--")
  #
  #       IO.puts([
  #         " Mixtank and Display Tank variance greater than ",
  #         Float.to_string(allowed_diff)
  #       ])
  #
  #       IO.puts([
  #         " Display Tank: ",
  #         Float.round(display_temp, 1) |> Float.to_string(),
  #         "   Mixtank: ",
  #         Float.round(mixtank_temp, 1) |> Float.to_string()
  #       ])
  #     end
  #
  #     {:failed, {:temp_diff, temp_diff}}
  #   else
  #     rmp() |> halt()
  #     rma() |> halt()
  #     ato() |> halt()
  #     swmt() |> ths_activate(standby())
  #     display_tank() |> ths_activate(standby())
  #
  #     status()
  #     {:ok}
  #   end
  # end
  #
  # def water_change_end do
  #   rmp() |> halt()
  #   rma() |> halt()
  #   ato() |> halt()
  #   swmt() |> ths_activate(standby())
  #   display_tank() |> ths_activate("75F")
  #
  #   status()
  # end
  #
  # def xfer_swmt_to_wst,
  #   do: dc_activate_profile(rmp(), "mx to wst")
  #
  # def xfer_wst_to_sewer,
  #   do: dc_activate_profile(rmp(), "drain wst")
  #
  # defp print_heading(text) when is_binary(text) do
  #   IO.puts(" ")
  #   IO.puts(light_yellow() <> underline() <> text <> reset())
  #   IO.puts(" ")
  # end
  #
  # defp print_usage(f, p),
  #   do:
  #     IO.puts(
  #       light_green() <>
  #         "USAGE: " <>
  #         light_blue() <>
  #         f <> "(" <> yellow() <> p <> light_blue() <> ")" <> reset()
  #     )
  #
  # def dc_activate_profile(name, p) do
  #   with {:ok, status} when is_list(status) <-
  #          Dutycycle.Server.activate_profile(name, p) do
  #     status
  #   else
  #     error -> ["error: ", inspect(error, pretty: true)] |> IO.puts()
  #   end
  # end
  #
  # def dc_halt(name) do
  #   with {:ok, status} when is_list(status) <-
  #          Dutycycle.Server.halt(name) do
  #     status
  #   else
  #     error -> ["error: ", inspect(error, pretty: true)] |> IO.puts()
  #   end
  # end
  #
  # def dc_resume(name) do
  #   with {:ok, status} when is_list(status) <-
  #          Dutycycle.Server.resume(name) do
  #     status
  #   else
  #     error -> inspect(error, pretty: true) |> IO.puts()
  #   end
  # end
  #
  # def dc_status(name, opts \\ [active: true]) do
  #   profile = Dutycycle.Server.profiles(name, opts)
  #
  #   %{
  #     subsystem: name,
  #     status: profile |> Map.get(:name),
  #     active: Dutycycle.Server.active?(name)
  #   }
  # end
  #
  # defp sensor_status(name) do
  #   temp_format = fn sensor ->
  #     temp = Sensor.fahrenheit(name: sensor, since_secs: 30)
  #
  #     if is_nil(temp) do
  #       temp
  #     else
  #       Float.round(temp, 1)
  #     end
  #   end
  #
  #   %{
  #     subsystem: name,
  #     status: temp_format.(name),
  #     active: "-"
  #   }
  # end
  #
  # def th_status(name, _opts) do
  #   with active_profile when is_struct(active_profile) <-
  #          Thermostat.Server.profiles(name, active: true) do
  #     %{
  #       subsystem: name,
  #       status: active_profile |> Map.get(:name),
  #       active: "-"
  #     }
  #   else
  #     error -> inspect(error, pretty: true) |> IO.puts()
  #   end
  # end
  #
  # # constants
  # defp ato, do: "display tank ato"
  # defp display_tank, do: "display tank"
  # defp dt, do: display_tank()
  # defp dt_sensor, do: "display_tank"
  # defp rmrf, do: "mix rodi"
  # defp rma, do: "mix air"
  # defp rmp, do: "mix pump"
  # defp standby, do: "standby"
  # defp swmt, do: "mix tank"
  # defp swmt_sensor, do: "mixtank"
  #
  # # help text
  # defp water_change_begin_help do
  #   ~S"""
  #   Water Change Begin Help
  #
  #     usage: water_change_begin(opts :: [Keyword.t])
  #
  #     Options:
  #
  #       check_diff: Boolean.t
  #         Default:  true
  #
  #         Check the difference between the Display Tank and Mixtank before
  #         beginning water change.  If the difference is less than or equal to
  #         allowed difference then proceed.  If the difference is greater than
  #         the allowed difference water change is not started.
  #
  #       allowed_diff: Float.t
  #         Default: 0.8
  #
  #         The allowed temperature difference between the Display Tank and Mixtank.
  #
  #     Examples:
  #       water_change_begin(check_diff: false)
  #       water_change_begin(allowed_diff: 0.9)
  #   """
  # end
end
