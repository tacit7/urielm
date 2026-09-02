defmodule Urielm.NewsBot.DateParser do
  @moduledoc false

  @months %{
    "January" => 1,
    "Jan" => 1,
    "February" => 2,
    "Feb" => 2,
    "March" => 3,
    "Mar" => 3,
    "April" => 4,
    "Apr" => 4,
    "May" => 5,
    "June" => 6,
    "Jun" => 6,
    "July" => 7,
    "Jul" => 7,
    "August" => 8,
    "Aug" => 8,
    "September" => 9,
    "Sep" => 9,
    "October" => 10,
    "Oct" => 10,
    "November" => 11,
    "Nov" => 11,
    "December" => 12,
    "Dec" => 12
  }

  def parse(date) do
    with [_, month_name, day, year] <- Regex.run(~r/^([A-Za-z]+) (\d{1,2}), (20\d{2})$/, date),
         month when is_integer(month) <- month_number(month_name),
         {day, ""} <- Integer.parse(day),
         {year, ""} <- Integer.parse(year),
         {:ok, date} <- Date.new(year, month, day) do
      {:ok, date}
    else
      _ -> :error
    end
  end

  def parse_rfc822(date) do
    with [_, day, month_name, year, hour, minute, second] <-
           Regex.run(
             ~r/^(?:[A-Za-z]{3}, )?(\d{1,2}) ([A-Za-z]{3}) (20\d{2}) (\d{2}):(\d{2}):(\d{2}) (?:GMT|\+0000)$/,
             date
           ),
         month when is_integer(month) <- month_number(month_name),
         {day, ""} <- Integer.parse(day),
         {year, ""} <- Integer.parse(year),
         {hour, ""} <- Integer.parse(hour),
         {minute, ""} <- Integer.parse(minute),
         {second, ""} <- Integer.parse(second),
         {:ok, date} <- Date.new(year, month, day),
         {:ok, time} <- Time.new(hour, minute, second),
         {:ok, datetime} <- DateTime.new(date, time, "Etc/UTC") do
      {:ok, datetime}
    else
      _ -> :error
    end
  end

  defp month_number(month_name), do: Map.get(@months, month_name)
end
