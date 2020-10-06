defmodule ExGram.Commands do
  @moduledoc """
  Checks the message passed for a specific command that the middleware handles.
  """

  # TODO: Maybe we should make this use an Encoder-like wrapper?
  def handle_command(handler, %{text: text} = message) do
    if text == handler.cmd do
      handler.execute(message)
    end
  end
end
