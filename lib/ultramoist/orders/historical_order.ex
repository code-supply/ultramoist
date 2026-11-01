defmodule Ultramoist.Orders.HistoricalOrder do
  @moduledoc false

  defstruct [:coin, :order_id, :order_type, :status, :status_time]

  def parse(%{"order" => order} = historical_order) do
    %__MODULE__{
      coin: order["coin"],
      order_id: order["oid"],
      order_type: order["orderType"],
      status: historical_order["status"],
      status_time: Ultramoist.Timestamp.parse(historical_order["statusTimestamp"])
    }
  end
end
