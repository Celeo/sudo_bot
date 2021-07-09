defmodule Bot.Application do
  use Application
  require Logger

  @impl true
  def start(_, _) do
    Logger.info("Starting application")
    children = [Bot.Consumer]
    opts = [strategy: :one_for_one, name: IRC.MainSupervisor]
    Supervisor.start_link(children, opts)
  end
end

defmodule Bot.Consumer do
  use Nostrum.Consumer
  require Logger

  def start_link do
    Logger.info("Starting consumer")
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    config = Bot.Config.load!()
    bot_user_id = Nostrum.Cache.Me.get().id

    bot_was_mentioned =
      Enum.find(msg.mentions, fn mentioned_user ->
        mentioned_user.id == bot_user_id
      end) != nil

    cond do
      msg.author.bot != nil or not bot_was_mentioned or length(msg.mention_roles) == 0 ->
        # IO.inspect({msg.author.bot != nil, bot_was_mentioned, length(msg.mention_roles) == 0},
        #   label: "noop reason"
        # )
        :noop

      not Enum.member?(config.allowed_user_ids, msg.author.id) ->
        Nostrum.Api.create_message!(
          msg.channel_id,
          content: "You're not allowed to use that",
          message_reference: %{message_id: msg.id}
        )

      true ->
        granted_roles =
          Enum.map(msg.mention_roles, fn role_id ->
            Nostrum.Api.add_guild_member_role(
              msg.guild_id,
              msg.author.id,
              role_id,
              "From Sudo Bot"
            )

            Bot.Scheduler.add(msg.author.id, role_id)
            role_obj = get_role_for_id(msg.guild_id, role_id)
            {role_id, role_obj.name}
          end)

        role_names =
          granted_roles
          |> Enum.map(fn {_, name} -> name end)
          |> Enum.join(", ")

        Nostrum.Api.create_message!(
          msg.channel_id,
          content: "You've been temporarily granted the following roles: #{role_names}",
          message_reference: %{message_id: msg.id}
        )
    end
  end

  def handle_event(_event), do: :noop

  defp get_role_for_id(guild_id, role_id) do
    Enum.find(Nostrum.Api.get_guild_roles!(guild_id), &(&1.id == role_id))
  end
end
