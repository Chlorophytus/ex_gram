defmodule Telex.Dispatcher do
  use GenServer

  require Logger

  def start_link([{:name, name} | rest]) do
    GenServer.start_link(__MODULE__, [:ok | rest], [name: name])
  end

  def init([:ok | rest]) do
    {:ok, Enum.into(rest, %{})}
  end

  defp is_implemented?(handler, behaviour) do
    case handler.module_info[:attributes][:behaviour] do
      nil -> false
      ls -> Enum.any?(ls, fn l -> l == behaviour end)
    end
  end

  defp handle_test_execute(handler, base, u) do
    if not is_nil(u) and is_implemented?(handler, base) do
      ht = handler.test(u)
      if ht do
        handler.execute(u)
      end
      ht
    else
      false
    end
  end

  # Handle messages!
  defp handle_message(handler,  u) do
    handle_test_execute(handler, Telex.Dsl.Message, u)
  end

  defp handle_callback_query(handler, u) do
    handle_test_execute(handler, Telex.Dsl.CallbackQuery, u)
  end

  defp dispatch_update(handler, u) do
    handle_test_execute(handler, Telex.Dsl.Base, u) ||
      handle_message(handler, u.message) ||
      handle_test_execute(handler, Telex.Dsl.EditedMessage, u.edited_message) ||
      handle_test_execute(handler, Telex.Dsl.ChannelPost, u.channel_post) ||
      handle_test_execute(handler, Telex.Dsl.EditedChannelPost, u.edited_channel_post) ||
      handle_test_execute(handler, Telex.Dsl.InlineQuery, u.inline_query) ||
      handle_test_execute(handler, Telex.Dsl.ChosenInlineResult, u.chosen_inline_result) ||
      handle_callback_query(handler, u.callback_query)
  end


  # EditedMessage
  # ChannelPost
  # EditedChannelPost
  # InlineQuery
  # ChosenInlineResult

  def handle_call({:update, u}, _from, %{dispatchers: dispatchers} = s) do
    Enum.map(dispatchers, &(dispatch_update(&1, u)))
    {:reply, :ok, s}
  end

  def handle_call({:update, u}, _from, s) do
    Logger.error "Update, not update? #{inspect(u)}\nState: #{inspect(s)}"
    {:reply, :error, s}
  end
end
