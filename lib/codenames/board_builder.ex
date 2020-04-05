defmodule Codenames.Board do
  @x_padding 20
  @y_padding 20
  @view_width 750
  @view_height 500
  @square_width 145
  @square_height 95

  @spec get_square_fill(boolean(), String.t()) :: String.t()
  def get_square_fill(show_fill, type) do
    if not show_fill do
      "white"
    else
      case type do
        "RED" ->
          "#ff4d4d"

        "BLUE" ->
          "#4169E1"

        "ASSASSIN" ->
          "#808080"

        "NEUTRAL" ->
          "#F5F5DC"
      end
    end
  end

  @spec get_square_x_coordinate(String.t()) :: number()
  def get_square_x_coordinate(column) do
    case column do
      "A" ->
        @x_padding

      "B" ->
        @x_padding + @square_width

      "C" ->
        @x_padding + @square_width * 2

      "D" ->
        @x_padding + @square_width * 3

      "E" ->
        @x_padding + @square_width * 4
    end
  end

  @spec get_x_axis_label_coordinate(String.t()) :: number()
  def get_x_axis_label_coordinate(column) do
    get_square_x_coordinate(column) + @square_width / 2 + 4
  end

  @spec get_y_axis_label_coordinate(String.t()) :: number()
  def get_y_axis_label_coordinate(row) do
    get_square_y_coordinate(row) + @square_height / 2
  end

  @spec get_square_y_coordinate(String.t()) :: number()
  def get_square_y_coordinate(row) do
    int = String.to_integer(row)
    @y_padding + @square_height * (int - 1)
  end

  @spec build_square(Codenames.Square.t(), boolean()) :: String.t()
  def build_square(square, public \\ true) do
    x_coord = get_square_x_coordinate(square.column)
    y_coord = get_square_y_coordinate(square.row)
    show_fill = not public or square.picked

    "<rect x=\"#{x_coord}\" y=\"#{y_coord}\" fill=\"#{get_square_fill(show_fill, square.type)}\" stroke=\"black\" height=\"#{
      @square_height
    }\" width=\"#{@square_width}\" />" <>
      "<text font-weight=\"bold\" style=\"font-size:18px;\" x=\"#{
        x_coord + @square_width / 2 - String.length(square.word) * 4
      }\" y=\"#{y_coord + @square_height / 2 + 6}\">#{square.word}</text>"
  end

  @spec wrap_board_content(String.t()) :: String.t()
  def wrap_board_content(content) do
    ret =
      "<svg viewBox=\"0 0 #{@view_width} #{@view_height}\" xmlns=\"http://www.w3.org/2000/svg\" xml:space=\"preserve\">" <>
        Enum.reduce(["A", "B", "C", "D", "E"], "", fn x, acc ->
          acc <>
            "<text style=\"font-size:16px;\" x=\"#{get_x_axis_label_coordinate(x)}\" y=\"16\">#{x}</text>"
        end) <>
        Enum.reduce(["1", "2", "3", "4", "5"], "", fn x, acc ->
          acc <>
            "<text style=\"font-size:16px;\" y=\"#{get_y_axis_label_coordinate(x)}\" x=\"6\">#{x}</text>"
        end) <>
        content <> "</svg>"

    IO.inspect(ret)
    ret
  end

  @spec build_public_board([Codenames.Square.t()]) :: String.t()
  def build_public_board(squares) do
    wrap_board_content(Enum.join(Enum.map(squares, fn x -> build_square(x, true) end)))
  end

  @spec build_key([Codenames.Square.t()]) :: String.t()
  def build_key(squares) do
    wrap_board_content(Enum.join(Enum.map(squares, fn x -> build_square(x, false) end)))
  end
end
