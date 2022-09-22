defmodule FullControlX.Driver do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def system_info(driver) do
    GenServer.call(driver, ["system_info"])
  end

  @impl true
  def init(:ok) do
    filename = "../fcxd/_build/FullControlX"
    port = Port.open({:spawn_executable, filename}, [:binary, :stream, :hide])
    {:ok, %{port: port}}
  end

  @impl true
  def handle_call(request, _from, state) do
    result = send_request(request, state)
    {:reply, result, state}
  end

  @impl true
  def handle_cast(request, state) do
    send_request(request, state)
    {:noreply, state}
  end

  @impl true
  def handle_info(message, state) do
    case message do
      {_port, {:data, data}} ->
        Jason.decode(data)
        |> IO.inspect()

      _ ->
        IO.inspect(handle_info_message: message)
    end

    {:noreply, state}
  end

  defp send_request(request, %{port: port}) when is_list(request) do
    {:ok, data} = Jason.encode_to_iodata(request)
    Port.command(port, data)
  end
end
