defmodule Telex.Bot do
  defmacro __using__(ops) do
    name =
      case Keyword.fetch(ops, :name) do
        {:ok, n} -> n
        _ -> raise "name parameter is mandatory"
      end

    username = Keyword.fetch(ops, :username)

    commands = quote do: commands()

    regexes = quote do: regexes()

    middlewares = quote do: middlewares()

    # quote location: :keep do
    quote do
      use Supervisor
      use Telex.Middleware.Builder

      import Telex.Dsl

      @behaviour Telex.Handler

      defp name(), do: unquote(name)

      def start_link(t, token \\ nil) do
        start_link(t, token, unquote(name))
      end

      defp start_link(m, token, name) do
        Supervisor.start_link(__MODULE__, {:ok, m, token, name}, name: name)
      end

      def init({:ok, updates_method, token, name}) do
        {:ok, _} = Registry.register(Registry.Telex, name, token)

        updates_worker =
          case updates_method do
            :webhook ->
              raise "Not implemented yet"

            :noup ->
              Telex.Noup

            :polling ->
              Telex.Updates.Worker

            other ->
              other
          end

        bot_info = maybe_fetch_bot(unquote(username), token)

        dispatcher_name = String.to_atom(Atom.to_string(name) <> "_dispatcher")

        dispatcher_opts = %Telex.Dispatcher{
          name: name,
          bot_info: bot_info,
          dispatcher_name: dispatcher_name,
          commands: unquote(commands),
          regex: unquote(regexes),
          middlewares: unquote(middlewares),
          handler: &handle/2
        }

        children = [
          worker(Telex.Dispatcher, [dispatcher_opts]),
          worker(updates_worker, [{:bot, dispatcher_name, :token, token}])
        ]

        supervise(children, strategy: :one_for_one)
      end

      def message(from, message) do
        GenServer.call(name(), {:message, from, message})
      end

      defp maybe_fetch_bot(username, _token) when is_binary(username),
        do: %Telex.Model.User{username: username, is_bot: true}

      defp maybe_fetch_bot(_username, token) do
        with {:ok, bot} <- Telex.get_me(token: token) do
          bot
        else
          _ -> nil
        end
      end
    end
  end
end
