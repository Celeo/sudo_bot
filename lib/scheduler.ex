defmodule Bot.Scheduler do
  use GenServer
  require Logger

  @tick_length 1000

  def start_link() do
    Logger.info("Starting bot scheduler")
    GenServer.start_link(__MODULE__, %{timer: nil, desudos: []})
  end

  @impl true
  def init(state) do
    timer = Process.send_after(self(), :tick, @tick_length)
    new_state = %{state | timer: timer}
    {:ok, new_state}
  end

  @impl true
  def handle_call({:add, user_id, role_id, delay}, _from, state) do
    clear_after = now_millis() + delay
    new_desudos = state.desudos ++ [{user_id, role_id, clear_after}]
    new_state = %{state | desudos: new_desudos}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:tick, _from, state) do
    now = now_millis()

    actionable =
      Enum.filter(state.desudos, fn {_, _, _, clear_after} ->
        clear_after <= now
      end)

    remaining =
      Enum.filter(state.desudos, fn {_, _, _, clear_after} ->
        clear_after > now
      end)

    Enum.each(actionable, fn {guild_id, user_id, role_id, _} ->
      Nostrum.Api.remove_guild_member_role(
        guild_id,
        user_id,
        role_id,
        "Sudo timeout by Sudo Bot"
      )
    end)

    :timer.cancel(state.timer)
    timer = Process.send_after(self(), :work, @tick_length)
    new_state = %{state | timer: timer, desudos: remaining}
    {:noreply, :ok, new_state}
  end

  # Return the current system Unix time in milliseconds.
  defp now_millis() do
    DateTime.now!("Etc/UTC") |> DateTime.to_unix(:millisecond)
  end

  @doc """
  Add a user ID and role ID to de-sudo after a
  delay (in seconds, default 300 [5 minutes]).
  """
  @spec add(guild_id :: integer(), user_id :: integer(), role_id :: integer(), delay :: integer()) ::
          :ok
  def add(guild_id, user_id, role_id, delay \\ 300) do
    GenServer.call(__MODULE__, {:add, guild_id, user_id, role_id, delay})
  end
end
