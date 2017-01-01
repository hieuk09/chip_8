require 'gosu'
require 'texplay'

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

    def button_down(key)
      @chip.press(key)
      self.caption = "Down ##{key}"
    end

    def button_up(key)
      @chip.release(key)
      self.caption = "Release ##{key}"
    end

    def update
      if @chip.running
        @chip.run(self)
        @timer += 1
      else
        close
      end
    end

    def draw
      if @chip.draw_flag
        display_buffer.draw(0, 0, 1)
      end
    end

    def update_buffer(display)
      display.each_with_index do |tile, x, y|
        color = tile == 0 ? Gosu::Color::BLACK : Gosu::Color::WHITE
        display_buffer.paint do
          rect x*10, y*10, (x + 1)*10, (y + 1)*10, color: color, fill: true
        end
      end
    end

    private

    def display_buffer
      @display_buffer ||= TexPlay.create_blank_image(self, WIDTH, HEIGHT)
    end
  end
end
