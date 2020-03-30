defmodule Codenames.Words do
  @moduledoc """
  Stores list of words used for games
  """

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def get_all(pid \\ __MODULE__) do
    GenServer.call(pid, :get_all)
  end

  def init(_) do
    words = File.read!("priv/words.json") |> Jason.decode!() |> Map.get("words")
    {:ok, words}
  end

  def handle_call(:get_all, _from, words) do
    {:reply, words, words}
  end
end
