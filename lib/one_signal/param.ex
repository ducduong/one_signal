defmodule OneSignal.Param do
  alias OneSignal.Param

  defstruct messages: %{}, headings: nil, platforms: nil, included_segments: nil, excluded_segments: nil, include_player_ids: nil, exclude_player_ids: nil, tags: nil, data: nil, ios_params: nil, android_params: nil, adm_params: nil, wp_params: nil, chrome_params: nil, firefox_params: nil, send_after: nil

  defp to_string_key({k, v}) do
    {to_string(k), v}
  end

  defp to_body({:headings, headings}) do
    body = headings
            |> Enum.map(&to_string_key/1)
            |> Enum.into(%{})
    {:headings, body}
  end
  defp to_body(body), do: body

  @doc """
  Send push notification from parameters
  """
  def notify(%Param{} = param, app_name \\ "") do
    param
    |> build(app_name)
    |> OneSignal.Notification.send(app_name)
  end

  @doc """
  Build notifications parameter of request
  """
  def build(%Param{} = param, app_name \\ "") do
    required = %{
      "app_id"   => OneSignal.fetch_app_id(app_name),
      "contents" => Enum.map(param.messages, &to_string_key/1) |> Enum.into(%{})
    }

    reject_params = [:messages, :platforms, :ios_params,
                     :android_params, :adm_params, :wp_params,
                     :chrome_params, :firefox_params]
    optionals = param
                |> Map.from_struct
                |> Enum.reject(fn {k, v} ->
                    k in reject_params or is_nil(v)
                end)
                |> Enum.map(&to_body/1)
                |> Enum.map(&to_string_key/1)
                |> Enum.into(%{})

    Map.merge(required, optionals)
  end

  @doc """
  Put message in parameters

  iex> OneSignal.new
       |> put_message(:en, "Hello")
       |> put_message(:ja, "はろー")
  """
  def put_message(%Param{} = param, message) do
    put_message(param, :en, message)
  end
  def put_message(%Param{} = param, language, message) do
    messages = Map.put(param.messages, language, message)
    %{param | messages: messages}
  end

  @doc """
  Put notification title.
  Notification title to send to Android, Amazon, Chrome apps, and Chrome Websites.

  iex> OneSignal.new
        |> put_heading("App Notice!")
        |> put_message("Hello")
  """
  def put_heading(%Param{} = param, heading) do
    put_heading(param, :en, heading)
  end
  def put_heading(%Param{headings: nil} = param, language, heading) do
    %{param | headings: %{language => heading}}
  end
  def put_heading(%Param{headings: headings} = param, language, heading) do
    headings = Map.put(headings, language, heading)
    %{param | headings: headings}
  end

  @doc """
  Put specific target segment

  iex> OneSignal.new
        |> put_message("Hello")
        |> put_segment("Top-Rank")
  """
  def put_segment(%Param{included_segments: nil} = param, segment) do
    %{param | included_segments: [segment]}
  end
  def put_segment(%Param{included_segments: seg} = param, segment) do
    %{param | included_segments: [segment|seg]}
  end

  @doc """
  Put segments
  """
  def put_segments(%Param{} = param, segs) do
    Enum.reduce(segs, param, fn next, acc -> put_segment(acc, next) end)
  end

  @doc """
  Drop specific target segment

  iex> OneSignal.new
       |> put_segment("Free Players")
       |> drop_segment("Free Players")
  """
  def drop_segment(%Param{included_segments: nil} = param, _seg) do
    param
  end
  def drop_segment(%Param{} = param, seg) do
    segs = Enum.reject(param.included_segments, &(&1 == seg))
    %{param | included_segments: segs}
  end

  @doc """
  Drop specific target segments
  """
  def drop_segments(%Param{} = param, segs) do
    Enum.reduce(segs, param, fn next, acc -> drop_segment(acc, next) end)
  end

  @doc """
  Exclude specific segment
  """
  def exclude_segment(%Param{excluded_segments: nil} = param, seg) do
    %{param | excluded_segments: [seg]}
  end
  def exclude_segment(%Param{excluded_segments: segs} = param, seg) do
    %{param | excluded_segments: [seg|segs]}
  end

  @doc """
  Exclude segments
  """
  def exclude_segments(%Param{} = param, segs) do
    Enum.reduce(segs, param, fn next, acc -> exclude_segment(acc, next) end)
  end

  @doc """
  Put player id
  """
  def put_player_id(%Param{include_player_ids: nil} = param, player_id) do
    %{param | include_player_ids: [player_id]}
  end
  def put_player_id(%Param{include_player_ids: ids} = param, player_id) do
    %{param | include_player_ids: [player_id|ids]}
  end

  def put_player_ids(%Param{} = param, player_ids) when is_list(player_ids) do
    Enum.reduce(player_ids, param, fn next, acc ->
      put_player_id(acc, next)
    end)
  end

  @doc """
  Exclude player id
  """
  def exclude_player_id(%Param{exclude_player_ids: nil} = param, player_id) do
    %{param | exclude_player_ids: [player_id]}
  end
  def exclude_player_id(%Param{exclude_player_ids: ids} = param, player_id) do
    %{param | exclude_player_ids: [player_id|ids]}
  end

  def exclude_player_ids(%Param{} = param, player_ids) when is_list(player_ids) do
    Enum.reduce(player_ids, param, fn next, acc ->
      exclude_player_id(acc, next)
    end)
  end

  @doc """
  Put data
  """
  def put_data(%Param{data: nil} = param, key, value) do
    %{param | data: %{key => value}}
  end

  def put_data(%Param{data: data} = param, key, value) do
    %{param | data: Map.put(data, key, value)}
  end

  def put_data(%Param{} = param, %{} = data) do
    Enum.reduce(data, param, fn({key, value}, p) -> put_data(p, key, value) end)
  end

end
