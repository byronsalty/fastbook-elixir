defmodule FastbookElixir do
  @moduledoc """
  Documentation for `FastbookElixir`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> FastbookElixir.hello()
      :world

  """
  def untar_data(url) do

    filename = Path.basename(url)
    # download the url
    data = HTTPoison.get!(url)
    # write the data to a file
    #File.write!(filename, data.body)


    # extract the tar file
    files = extract_tar_from_binary(data.body)
    IO.inspect(files)
  end

  def extract_tar_from_binary(binary) do
    # https://gist.github.com/nroi/d4b0716a987c46534c04eb6611b78703

    with {:ok, files} <- :erl_tar.extract({:binary, binary}, [:memory, :compressed]) do
      files
      |> Enum.map(fn {filename, content} -> {to_string(filename), content} end)
      |> Map.new
    end
  end
end
