defmodule TEST_SERVER do
  @moduledoc """
  Implements a simple key/value storage datatbase.
  """

  @spec call(pid(), term()) :: term()
  def call(pid, message) do
    # IO.puts "sending call"
    send pid, {:call, self(), message}
    # IO.puts "waiting on response"
    receive do
      response ->
        # IO.puts "response received"
        response
    end
  end

  @spec cast(pid(), term()) :: :ok
  def cast(pid, message) do
    send pid, {:cast, message}
    :ok
  end

  @spec server_loop({atom, map}) :: atom
  def server_loop(state = {:running, dict}) do
    receive do
      {:call, pid, message} when is_pid pid ->
        # Handle calls
        case message do
          {:keys} ->
            send pid, Enum.join(Map.keys(dict), ", ")
            server_loop(state)
          {:put, key, value} ->
            send pid, :ok
            server_loop({:running, Map.put(dict, key, value)})
          {:get, key} ->
            send pid, dict[key]
            server_loop(state)
          {:delete, key} ->
            send pid, :ok
            server_loop({:running, Map.delete(dict, key)})
        end
      {:cast, message} ->
        # Handle casts
        case message do
          {:stop} ->
            server_loop({:stopped, dict})
        end
    end
  end
  def server_loop(state) do
    IO.puts "Process with PID: #{self()} exited with state: \n#{state}"
  end

  @spec io_loop(pid()) :: :ok
  def io_loop(server_pid) do
    result = case String.split(String.downcase(IO.gets("> "))) do
      ["burger"] ->
        IO.puts(
        """
          .-'''-.
          |       `.
         /           \
        |             ;
         \           /
          `._     _.'
            `''''
        """)
      ["help"] ->
        IO.puts(
  "Available commands:
  put <KEY> <VALUE>
  get <KEY>
  delete <KEY>
  keys
  exit")
      ["get", key] ->
        call server_pid, {:get, key}
      ["put", key | value] ->
        call server_pid, {:put, key, value}
      ["delete", key] ->
        call server_pid, {:delete, key}
      ["keys"] ->
        call server_pid, {:keys}
      ["exit"] ->
        cast server_pid, {:exit}
        :exit
      other ->
        IO.puts "Unknown command: \"#{other}\""
        :unknown_command
    end

    IO.puts "\nReturned: #{result}"

    case result do
      :exit ->
        :ok
      _ ->
        io_loop(server_pid)
    end
  end

  @spec start_server() :: pid()
  def start_server() do
    spawn(fn -> server_loop({:running, %{}}) end)
  end

  @spec start() :: :ok
  def start() do
    IO.puts "Type 'help' for a list of available commands"
    start_server() |> io_loop
  end
end
