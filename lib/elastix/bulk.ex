defmodule Elastix.Bulk do
  @moduledoc """
  The bulk API makes it possible to perform many index/delete operations in a single API call.

  [Elastic documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html)
  """
  import Elastix.HTTP, only: [prepare_url: 2]

  alias Elastix.HTTP
  

  @doc """
  Excepts a list of actions and sources for the `lines` parameter.

  ## Examples

      iex> Elastix.Bulk.post("http://localhost:9200", [%{index: %{_id: "1"}}, %{user: "kimchy"}], index: "twitter", type: "tweet")
      {:ok, %HTTPoison.Response{...}}
  """
  @spec post(elastic_url :: String.t(), lines :: list, opts :: Keyword.t(), query_params :: Keyword.t()) :: HTTP.resp()
  def post(elastic_url, lines, options \\ [], query_params \\ []) do
    data =
      lines
      |> Enum.reduce([], fn l, acc -> ["\n", JSON.encode!(l) | acc] end)
      |> Enum.reverse()
      |> IO.iodata_to_binary()

    path =
      options
      |> Keyword.get(:index)
      |> make_path(Keyword.get(options, :type), query_params)

    httpoison_options = Keyword.get(options, :httpoison_options, [])

    elastic_url
    |> prepare_url(path)
    |> HTTP.put(data, [], httpoison_options)
  end

  @doc """
  Deprecated: use `post/4` instead.
  """
  @spec post_to_iolist(elastic_url :: String.t(), lines :: list, opts :: Keyword.t(), query_params :: Keyword.t()) ::
          HTTP.resp()
  def post_to_iolist(elastic_url, lines, options \\ [], query_params \\ []) do
    IO.warn("This function is deprecated and will be removed in future releases; use Elastix.Bulk.post/4 instead.")

    httpoison_options = Keyword.get(options, :httpoison_options, [])

    HTTP.put(
      elastic_url <> make_path(Keyword.get(options, :index), Keyword.get(options, :type), query_params),
      Enum.map(lines, fn line -> JSON.encode!(line) <> "\n" end),
      [],
      httpoison_options
    )
  end

  @doc """
  Same as `post/4` but instead of sending a list of maps you must send raw binary data in
  the format described in the [Elasticsearch documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html).
  """
  @spec post_raw(elastic_url :: String.t(), raw_data :: String.t(), opts :: Keyword.t(), query_params :: Keyword.t()) ::
          HTTP.resp()
  def post_raw(elastic_url, raw_data, options \\ [], query_params \\ []) do
    httpoison_options = Keyword.get(options, :httpoison_options, [])

    HTTP.put(
      elastic_url <> make_path(Keyword.get(options, :index), Keyword.get(options, :type), query_params),
      raw_data,
      [],
      httpoison_options
    )
  end

  @doc false
  def make_path(index_name, type_name, query_params) do
    path = make_base_path(index_name, type_name)

    case query_params do
      [] -> path
      _ -> HTTP.append_query_string(path, query_params)
    end
  end

  defp make_base_path(nil, nil), do: "/_bulk"
  defp make_base_path(index_name, nil), do: "/#{index_name}/_bulk"
  defp make_base_path(index_name, type_name), do: "/#{index_name}/#{type_name}/_bulk"
end
