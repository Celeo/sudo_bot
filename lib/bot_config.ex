defmodule Bot.Config do
  defstruct [
    :sudoable_roles,
    :allowed_user_ids
  ]

  @doc """
  Get the name of the config's file.
  """
  def file_name!() do
    Application.fetch_env!(:sudo_bot, :config_file_name)
  end

  @doc """
  Read the file from the disk and return a struct of its contents.
  """
  def load!() do
    content = File.read!(file_name!())
    Poison.decode!(content, as: %Bot.Config{})
  end
end
