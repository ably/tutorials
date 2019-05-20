defmodule AblySseDemo.Subscriber do
  require Logger
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_) do
    api_key = Application.get_env(:ably_sse_demo, :api_key)
    channels = Application.get_env(:ably_sse_demo, :channels)
    version = Application.get_env(:ably_sse_demo, :version)

    if is_nil(api_key) do
      raise "No API key found. Add it to config/config.exs, or run as API_KEY=your.api:key_here mix run"
    end

    if is_nil(channels) do
      raise "No channels specified. Add to config/config.exs, or run as CHANNELS=some_channel,other_channel mix run"
    end

    query_params =
      encode_query(
        channels: channels,
        key: api_key,
        v: version
      )

    Logger.info("Starting event stream of channels #{channels |> String.split(",") |> inspect}")

    {:ok, evsrc_pid} =
      EventsourceEx.new("https://realtime.ably.io/sse?#{query_params}",
        stream_to: self()
      )

    {:ok, %{evsrc_pid: evsrc_pid}}
  end

  def handle_info(%EventsourceEx.Message{data: data, event: event_type}, state) do
    level =
      case event_type do
        "error" -> :warn
        _ -> :info
      end

    Logger.log(level, "Received a #{event_type} from Ably: #{display(data)}")
    {:noreply, state}
  end

  defp encode_query(qs_params) do
    Enum.map_join(qs_params, "&", fn {k, v} ->
      to_string(k) <> "=" <> to_string(v)
    end)
  end

  defp display(data) do
    data
    |> Poison.decode!(keys: :atoms)
    |> inspect(pretty: true)
  end
end
