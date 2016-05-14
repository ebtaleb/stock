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
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        IO.puts "Instance #{instance_id} restarted"
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
    end
  end

  def stop_instance(instance_id) do
    url = "#{gm_url}/instances/#{instance_id}/stop"
    headers = [{"Cookie", "api_key=#{api_token}"}]

    case Stockastic.post(url, "", headers, []) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        IO.puts "Instance #{instance_id} stopped"
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
    end
  end

  def resume_instance(instance_id) do
    url = "#{gm_url}/instances/#{instance_id}/resume"
    headers = [{"Cookie", "api_key=#{api_token}"}]

    case Stockastic.post(url, "", headers, []) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
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

  #def place_order(price, amount, dir, order_type) do

    #order = %{
      #account:   account,
      #venue:     venue,
      #stock:     ticker,
      #price:     price,
      #qty:       amount,
      #direction: dir,
      #orderType: order_type
    #}

    #Stockastic.Orders.place_order(venue, stock, order, client)
  #end

  def main do

    client = get_client
    instance_data = new_instance("chock_a_block")

    account = instance_data["account"] 
    instance_id = instance_data["instanceId"] 
    secondsPerTradingDay = instance_data["secondsPerTradingDay"] 
    ticker = hd(instance_data["tickers"])
    venue = hd(instance_data["venues"])

    #lvl_stats(instance_id)

    #IO.puts "listing stocks for venue #{venue}"
    #Stockastic.Stocks.list(venue, client)

    #IO.puts "listing orders for stock #{ticker} on venue #{venue}"
    #Stockastic.Orders.list_for_stock(venue, account, ticker, client)

    IO.puts "fetching orderbook for stock #{ticker} on venue #{venue}"
    Stockastic.Stocks.orderbook(venue, ticker, client)

    #IO.puts "cancelling order 1 for stock #{ticker} on venue #{venue}"
    #Stockastic.Orders.cancel(venue, ticker, 1, client)
    #Stockastic.Orders.cancel(venue, ticker, id, client)
    #cancel(id)

    #place_order(price, amount, dir, order_type)

    #stop_instance(instance_id)
  end

end
