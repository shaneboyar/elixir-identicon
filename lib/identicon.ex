defmodule Identicon do
  @moduledoc """
  Documentation for Identicon.
  """

  @doc """
  The main function of the Identicon module.
  Takes a string and deterministically returns
  an abstract image
"""
  def main(input) do
    input
    |> hash_input
    |> pick_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> draw_image
    |> save_image(input)
  end

  def save_image(image, input) do
    File.write("#{input}.png", image)
  end

  def draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.each pixel_map, fn({start, stop}) ->
      :egd.filledRectangle(image, start, stop, fill)
    end

    :egd.render(image)
  end

  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map = Enum.map grid, fn({_code, index}) ->
      horizontal = rem(index, 5) * 50
      vertical = div(index, 5) * 50
      top_left = {horizontal, vertical}
      bottom_right  = {horizontal + 50, vertical + 50}

      {top_left, bottom_right}
    end

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  @doc """
  Since only the odd coded squares will be colored, we can discared the evens.
  """

  def filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    grid = Enum.filter grid, fn({code, _index}) ->
      rem(code, 2) == 0
    end

    %Identicon.Image{image | grid: grid}
  end

  def build_grid(%Identicon.Image{hex: hex} = image) do
    grid =
      hex
      |> Enum.chunk(3)
      |> Enum.map(&mirror_row/1)
      |> List.flatten
      |> Enum.with_index

    %Identicon.Image{image | grid: grid}
  end

  @doc """
  Helper function that takes a list of 3 numbers and mirrors it.

  ## Examples

      iex> Identicon.mirror_row([1, 2, 3])
      [1, 2, 3, 2, 1]
  """

  def mirror_row(row) do
    [first, second, _tail] = row
    row ++ [second, first]
  end

  @doc """
  Takes a struct containing only an array of hex numbers
  and returns an array containing three hex values that
  represent the color of the identicon

  ## Examples

      iex> image = Identicon.hash_input('input')
      iex> Identicon.pick_color(image)
      %Identicon.Image{color: {164, 27, 60}, grid: nil,
        hex: [164, 60, 27, 10, 165, 58, 12, 144, 136, 16, 192, 106, 177, 255, 57, 103],
        pixel_map: nil}
  """

  def pick_color(%Identicon.Image{hex: [r, g, b | _tail]} = image) do
    %Identicon.Image{image | color: {r, b, g}}
  end

  @doc """
  Returns an image struct containing a hex list for a given input

  ## Examples

      iex> Identicon.hash_input('input')
      %Identicon.Image{hex: [164, 60, 27, 10, 165, 58, 12, 144, 136, 16, 192, 106, 177, 255, 57, 103]}
  """
  def hash_input(input) do
    hex = :crypto.hash(:md5, input)
    |> :binary.bin_to_list

    %Identicon.Image{hex: hex}
  end
end
