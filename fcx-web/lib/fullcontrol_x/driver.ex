defmodule FullControlX.Driver do
  require Logger
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

  def apps_observe(driver) do
    GenServer.call(driver, ["apps_observe"])
  end

  @impl true
  def init(:ok) do
    filename = "../fcxd/_build/FullControlX"
    port = Port.open({:spawn_executable, filename}, [:binary, :stream, :hide])

    {:ok,
     %{
       port: port,
       next_req_id: 1,
       awating: %{},
       data: <<>>
     }}
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
    {messages, state} = parse(data, state)
    IO.inspect(messages_count: Enum.count(messages), messages: messages)

    Enum.reduce(messages, state, fn message, state ->
      with %{"request" => [req_id | _]} = message when not is_nil(req_id) <- message,
           %{awating: %{^req_id => from} = awating} <- state do
        GenServer.reply(from, Map.get(message, "response"))
        %{state | awating: Map.delete(awating, req_id)}
      else
        _ -> state
      end
    end)

    {:noreply, state}
  end

  def handle_info(message, state) do
    IO.inspect(handle_info_message: message)
    {:noreply, state}
  end

  defp parse(data, %{data: previous_data} = state) do
    to_parse = previous_data <> data

    case split_data(to_parse, <<>>, []) do
      {message_data, remains} ->
        messages =
          Enum.map(message_data, fn message_data ->
            with {:ok, message} <- Jason.decode(message_data) do
              IO.inspect([remains: remains], binaries: :as_binaries)
              message
            else
              _ ->
                Logger.error(message_data: message_data, remains: remains)
                nil
            end
          end)

        {messages, %{state | data: remains}}

      _ ->
        {nil, state}
    end
  end

  defp split_data(<<>>, _parsed, _list) do
    :not_found
  end

  defp split_data(<<0::8>>, parsed, list) do
    {List.insert_at(list, -1, parsed), <<>>}
  end

  defp split_data(<<0::8, rest::binary>>, parsed, list) do
    split_data(rest, <<>>, List.insert_at(list, -1, parsed))
  end

  defp split_data(<<value, rest::binary>>, parsed, list) do
    split_data(rest, parsed <> <<value>>, list)
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
