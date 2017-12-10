defmodule Telex.Responses.EditInline do
  defstruct [:text, :message_id, :chat_id, :inline_message_id, :ops]
end

defimpl Telex.Responses, for: Telex.Responses.EditInline do
  def new(response, params), do: struct(response, params)

  def execute(%{inline_message_id: nil, ops: ops} = edit) do
    new_ops =
      ops |> Keyword.put(:message_id, edit.message_id) |> Keyword.put(:chat_id, edit.chat_id)

    Telex.edit_message_text(edit.text, new_ops)
  end

  def execute(%{inline_message_id: mid, ops: ops} = edit) do
    new_ops = Keyword.put(ops, :inline_message_id, mid)

    Telex.edit_message_text(edit.text, new_ops)
  end

  def set_msg(%{message_id: nil, chat_id: nil, inline_message_id: nil} = response, msg) do
    Map.merge(response, Telex.Dsl.extract_inline_id_params(msg))
  end

  def set_msg(response, _msg), do: response
end
