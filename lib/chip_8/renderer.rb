require 'gosu'

module Chip8
  class Renderer < Gosu::Window
    WIDTH = 640
    HEIGHT = 320

    def initialize(chip: chip)
      super(WIDTH, HEIGHT)
      @timer = 0
      @chip = chip
    end

    def clear
      @timer = 0
    end

    def update
      if @chip.running
        self.caption = "Something #{@timer}"
        @chip.run

        if @chip.draw_flag
          @chip.display.each_with_index do |tile, x, y|
            color = tile == 0 ? Gosu::Color::BLACK : Gosu::Color::WHITE
            draw_quad(
              x, y, color,
              x + 9, y, color,
              x, y + 9, color,
              x + 9, y + 9, color,
              0
            )
          end
        end

        @timer += 1
      end
    end
  end
end
