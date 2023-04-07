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

    # download the url
    data = HTTPoison.get!(url)

    # extract the tar file
    extract_tar_from_binary(data.body)
  end

  def extract_tar_from_binary(binary) do
    # https://gist.github.com/nroi/d4b0716a987c46534c04eb6611b78703

    with {:ok, files} <- :erl_tar.extract({:binary, binary}, [:memory, :compressed]) do
      files
      |> Enum.map(fn {filename, content} -> {to_string(filename), content} end)
      |> Map.new
    end
  end

  def show_image(tensor) do
    tensor =
      if Nx.rank(tensor) == 2 do
        Nx.reshape(tensor, Tuple.append(Nx.shape(tensor), 1))
      else
        tensor
      end

    tensor =
      if Nx.type(tensor) == {:f, 32} do
        tensor
        |> Nx.multiply(255)
        |> Nx.floor()
        |> Nx.as_type(:u8)
      else
        tensor
      end

    Kino.Image.new(tensor)
  end
end
