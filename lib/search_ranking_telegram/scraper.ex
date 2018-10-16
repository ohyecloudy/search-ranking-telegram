defmodule SearchRankingTelegram.Scraper do
  use GenServer
  use Hound.Helpers
  require Logger
  alias SearchRankingTelegram.Telegram

  @interval_ms 1000 * 60

  def start_link(:ok) do
    Logger.info("start #{__MODULE__}")
    GenServer.start_link(__MODULE__, :ok)
  end

  @impl true
  def init(:ok) do
    Task.start(fn ->
      # TODO[ohyecloudy]: chrome driver 프로세스 수명도 같이 제어해야 한다
      System.cmd(Application.get_env(:search_ranking_telegram, :chrome_driver_path), [])
    end)

    {:ok, _} = Application.ensure_all_started(:hound)
    Hound.start_session()

    ret = scraping()
    Telegram.broadcast("#{inspect(ret)}")
    schedule_work()

    {:ok, %{}}
  end

  @impl true
  def handle_info(:scraping, state) do
    ret = scraping()
    Telegram.broadcast("#{inspect(ret)}")
    schedule_work()

    {:noreply, state}
  end

  defp schedule_work() do
    Process.send_after(self(), :scraping, @interval_ms)
  end

  defp scraping() do
    Logger.info("scraping")

    navigate_to("https://www.naver.com/")

    find_all_elements(:class, "ah_item")
    |> Enum.filter(fn e -> attribute_value(e, "data-order") end)
    |> Enum.map(fn e ->
      {find_within_element(e, :class, "ah_r") |> inner_text(),
       find_within_element(e, :class, "ah_k") |> inner_text()}
    end)
  end
end
