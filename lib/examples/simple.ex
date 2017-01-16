defmodule Examples.Simple do
  @bot :simple_bot
  def bot(), do: @bot

  use Telex.Bot, name: @bot
  use Telex.Dsl

  dispatch Examples.Echo

  defmodule EchoCmd do
    def bot, do: Examples.Simple.bot()

    use Telex.Dsl.Command, "echo"
    def execute(%{text: t} = msg) do
      answer msg, t, bot: bot()
    end
  end


  def echo_c(msg) do
    %{text: t} = msg
    answer msg, t, bot: @bot
  end
  command EchoCmd, "echo", &Examples.Simple.echo_c/1

  regex "HoliCmd", "/holi", Examples.Simple do
    answer msg, "Holiiii!", bot: @bot
  end

  message Logger, &(Logger.info "Message received: #{inspect(&1)}")

  update Updater, Examples.Simple do
    Logger.info "Update received: #{inspect(update)}"
  end
end
