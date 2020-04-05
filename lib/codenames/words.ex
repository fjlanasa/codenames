defmodule Codenames.Words do
  @moduledoc """
  Stores list of words used for games
  """

  use GenServer

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_all(pid \\ __MODULE__) do
    GenServer.call(pid, :get_all)
  end

  def get_words_for_game(pid \\ __MODULE__) do
    GenServer.call(pid, :get_words_for_game)
  end

  def init(_) do
    words = File.read!("priv/words.json") |> Jason.decode!() |> Map.get("words")
    {:ok, words}
  end

  def handle_call(:get_all, _from, words) do
    {:reply, words, words}
  end

  def handle_call(:get_words_for_game, _from, words) do
    words_for_game = words |> Enum.shuffle() |> Enum.slice(0..24)
    {:reply, words_for_game, words}
  end
end
