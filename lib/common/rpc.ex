defmodule RPC do
  @moduledoc """
    Remore Procedure Call Support
  """

  @doc """
    Retrieve the configured RPC host from the Application environment.

    Raised RuntimeError if the key :rpc_host is not present in the environment.

    ## Examples

      iex> RPC.host()
      :"prod@helen.live.wisslanding.com"
  """
  def host do
    h = Application.get_env(:vera, :rpc_host)

    if is_nil(h) do
      raise("key :rpc_host not in environment")
    else
      h
    end
  end
end
