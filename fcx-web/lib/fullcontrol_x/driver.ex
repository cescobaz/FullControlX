defmodule FullControlX.Driver do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def system_info(driver) do
    GenServer.call(driver, ["system_info"])
  end

  def ui_apps(driver) do
    GenServer.call(driver, ["ui_apps"])
  end

  @impl true
  def init(:ok) do
    filename = "../fcxd/_build/FullControlX"
    port = Port.open({:spawn_executable, filename}, [:binary, :stream, :hide])
    {:ok, %{port: port, next_req_id: 1, awating: %{}}}
  end

  @impl true
  def handle_call(request, from, %{awating: awating} = state) do
    {req_id, state} = send_request(request, state)
    {:noreply, %{state | awating: Map.put(awating, req_id, from)}}
  end

  @impl true
  def handle_cast(request, state) do
    {_, state} = send_request(request, state)
    {:noreply, state}
  end

  @impl true
  def handle_info({_port, {:data, data}}, state) do
    message = Jason.decode(data)
    IO.inspect(message: message)

    state =
      with {:ok, %{"request" => [req_id | _]} = message} when not is_nil(req_id) <- message,
           %{awating: %{^req_id => from} = awating} <- state do
        GenServer.reply(from, Map.get(message, "response"))
        %{state | awating: Map.delete(awating, req_id)}
      else
        _ -> state
      end

    {:noreply, state}
  end

  def handle_info(message, state) do
    IO.inspect(handle_info_message: message)
    {:noreply, state}
  end

  defp send_request(request, %{port: port, next_req_id: req_id} = state)
       when is_list(request) do
    {:ok, data} = Jason.encode_to_iodata([req_id | request])

    if Port.command(port, data) do
      {req_id, %{state | next_req_id: req_id + 1}}
    else
      {nil, state}
    end
  end
end
