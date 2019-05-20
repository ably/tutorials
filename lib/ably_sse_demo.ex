defmodule AblySseDemo do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(AblySseDemo.Subscriber, [])
    ]

    opts = [strategy: :one_for_one, name: AblySseDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
