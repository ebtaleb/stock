defmodule Stock do

  def api_token do
    "b2ce6570f554ae497f21c4d11e45e113bddc9c5f"
  end

  def gm_url do
    "https://www.stockfighter.io/gm"
  end

  def get_client do
    Stockastic.start
    Stockastic.Client.new(%{access_token: api_token})
  end

  def parse(body) do
    case JSX.decode body do
      {:ok, dict} -> dict
      {_, _} -> IO.puts "error parsing JSON"
    end
  end

  def instance_info(body) do
    case JSX.decode body do
      {:ok, dict} -> Map.delete(dict, "instructions")
      {_, _} -> IO.puts "error parsing JSON"
    end
  end

  def new_instance(lvl_name) do
    url = "#{gm_url}/levels/#{lvl_name}"
    headers = [{"Cookie", "api_key=#{api_token}"}]

    case Stockastic.post(url, "", headers, []) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        data = instance_info body
        IO.puts "New instance #{data["instanceId"]} created"
        data
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
    end
  end

  def restart_instance(instance_id) do
    url = "#{gm_url}/instances/#{instance_id}/restart"
    headers = [{"Cookie", "api_key=#{api_token}"}]

    case Stockastic.post(url, "", headers, []) do
      {:ok, %HTTPoison.Response{status_code: 200, body: _}} ->
        IO.puts "Instance #{instance_id} restarted"
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
    end
  end

  def stop_instance(instance_id) do
    url = "#{gm_url}/instances/#{instance_id}/stop"
    headers = [{"Cookie", "api_key=#{api_token}"}]

    case Stockastic.post(url, "", headers, []) do
      {:ok, %HTTPoison.Response{status_code: 200, body: _}} ->
        IO.puts "Instance #{instance_id} stopped"
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
    end
  end

  def resume_instance(instance_id) do
    url = "#{gm_url}/instances/#{instance_id}/resume"
    headers = [{"Cookie", "api_key=#{api_token}"}]

    case Stockastic.post(url, "", headers, []) do
      {:ok, %HTTPoison.Response{status_code: 200, body: _}} ->
        IO.puts "Instance #{instance_id} resumed"
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
    end
  end

  def lvl_stats(instance_id) do
    url = "#{gm_url}/instances/#{instance_id}"
    headers = [{"Cookie", "api_key=#{api_token}"}]

    case Stockastic.request(:get, url, "", headers, []) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        parse(body)
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
    end
  end

  def init_state do
    instance_data = new_instance("chock_a_block")
    {:ok, state} = KV.start_link(instance_data)
    KV.put(state, "client", get_client)
    state
  end

  def get_account(s) do
    KV.get(s, "account")
  end

  def get_instanceId(s) do
    KV.get(s, "instanceId")
  end

  def get_1st_ticker(s) do
    hd(KV.get(s, "tickers"))
  end

  def list_tickers(s) do
    KV.get(s, "tickers")
  end

  def get_1st_venue(s) do
    hd(KV.get(s, "venues"))
  end

  def list_venues(s) do
    KV.get(s, "venues")
  end

  def get_client(s) do
    KV.get(s, "client")
  end

  def get_orderbook(s) do
    ticker = get_1st_ticker(s)
    venue = get_1st_venue(s)
    client = get_client(s)

    IO.puts "fetching orderbook for stock #{ticker} on venue #{venue}"
    Stockastic.Stocks.orderbook(venue, ticker, client)
  end

  def get_orderbook(s, t, v) do
    ticker = t
    venue = v
    client = get_client(s)

    IO.puts "fetching orderbook for stock #{ticker} on venue #{venue}"
    Stockastic.Stocks.orderbook(venue, ticker, client)
  end

  def list_stocks(s) do
    venue = get_1st_venue(s)
    IO.puts "listing stocks for venue #{venue}"
    Stockastic.Stocks.list(venue, get_client(s))
  end

  def list_stocks(s, venue) do
    IO.puts "listing stocks for venue #{venue}"
    Stockastic.Stocks.list(venue, get_client(s))
  end

  def list_orders(s, t, v) do
    IO.puts "listing orders for stock #{t} on venue #{v}"
    Stockastic.Orders.list_for_stock(v, get_account(s), t, get_client(s))
  end

  def list_orders(s) do
    t = get_1st_ticker(s)
    v = get_1st_venue(s)
    IO.puts "listing orders for stock #{t} on venue #{v}"
    Stockastic.Orders.list_for_stock(v, get_account(s), t, get_client(s))
  end

  def place_order(s, price, amount, dir) do
    stock = get_1st_ticker(s)
    venue = get_1st_venue(s)

    order = %{
      account:   get_account(s),
      venue:     venue,
      stock:     stock,
      price:     price,
      qty:       amount,
      direction: dir,
      orderType: "limit"
    }

    IO.puts "#{dir}ing #{amount} stocks of #{stock} on venue #{venue}"
    Stockastic.Orders.place_order(venue, stock, order, get_client(s))
  end

  def place_order(s, price, amount, dir, stock, venue) do

    order = %{
      account:   get_account(s),
      venue:     venue,
      stock:     stock,
      price:     price,
      qty:       amount,
      direction: dir,
      orderType: "limit"
    }

    IO.puts "#{dir}ing #{amount} stocks of #{stock} on venue #{venue}"
    Stockastic.Orders.place_order(venue, stock, order, get_client(s))
  end

  def cancel(s, id) do
    ticker = get_1st_ticker(s)
    venue = get_1st_venue(s)
    IO.puts "cancelling order #{id} for stock #{ticker} on venue #{venue}"
    Stockastic.Orders.cancel(venue, ticker, id, get_client(s))
  end

  def cancel(s, id, t, v) do
    IO.puts "cancelling order #{id} for stock #{t} on venue #{v}"
    Stockastic.Orders.cancel(v, t, id, get_client(s))
  end

  def ticker_tape(s) do
    url = "api.stockfighter.io"
    url_path = "/ob/api/ws/#{get_account(s)}/venues/#{get_1st_venue(s)}/tickertape/stocks/#{get_1st_ticker(s)}"
    socket = Socket.Web.connect! url, path: url_path, secure: true
    case socket |> Socket.Web.recv! do
      {:text, data} -> parse(data)
      {:ping, _ } ->
        socket |> Socket.Web.send!({:pong, ""})
    end
  end

  def fills(s) do
    url = "api.stockfighter.io"
    url_path = "/ob/api/ws/#{get_account(s)}/venues/#{get_1st_venue(s)}/executions/stocks/#{get_1st_ticker(s)}"
    socket = Socket.Web.connect! url, path: url_path, secure: true
    case socket |> Socket.Web.recv! do
      {:text, data} -> parse(data)
      {:ping, _ } ->
        socket |> Socket.Web.send!({:pong, ""}); socket |> Socket.Web.recv!
    end
  end

end
