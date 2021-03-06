defmodule SearchRankingTelegram.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: SearchRankingTelegram.Worker.start_link(arg)
      # {SearchRankingTelegram.Worker, arg},
      {SearchRankingTelegram.Telegram, :ok},
      {SearchRankingTelegram.Scraper, :ok}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SearchRankingTelegram.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
