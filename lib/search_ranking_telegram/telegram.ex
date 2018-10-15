defmodule SearchRankingTelegram.Telegram do
  use GenServer
  require Logger

  @interval_ms 1000

  defmodule State do
    defstruct offset: nil, chat_id_list: []
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    schedule_update()
    {:ok, %State{}}
  end

  def broadcast(msg) do
    GenServer.cast(__MODULE__, {:broadcast, msg})
  end

  def handle_cast({:broadcast, msg}, state) do
    state.chat_id_list
    |> Enum.each(fn chat_id ->
      Nadia.send_message(chat_id, msg)
    end)

    {:noreply, state}
  end

  def handle_info(:update, state) do
    schedule_update()

    ret =
      if state.offset do
        Nadia.get_updates(offset: state.offset, timeout: 5)
      else
        Nadia.get_updates()
      end

    {state, new_offset} = process_messages(state, ret)

    {:noreply, %{state | offset: new_offset + 1}}
  end

  defp schedule_update() do
    Process.send_after(self(), :update, @interval_ms)
  end

  defp process_messages(state, {:ok, []}), do: {state, -1}

  defp process_messages(state, {:ok, results}) do
    results
    |> Enum.reduce({state, -1}, fn %{update_id: id} = message, {state, _update_id} ->
      state = process_message(state, message)

      {state, id}
    end)
  end

  defp process_message(_state, {:error, error}) do
    Logger.warn("error - #{inspect(error)}")
  end

  defp process_message(state, message) do
    msg = message.message

    if msg do
      text = msg.text
      chat_id = msg.chat.id

      case String.trim(text) do
        "/start" ->
          state =
            put_in(
              state.chat_id_list,
              Enum.uniq(state.chat_id_list ++ [chat_id])
            )

          Logger.info("#{inspect(state)}")
          state

        "/end" ->
          state =
            put_in(
              state.chat_id_list,
              List.delete(state.chat_id_list, chat_id)
            )

          Logger.info("#{inspect(state)}")
          state

        _ ->
          state
      end
    else
      state
    end
  end
end
