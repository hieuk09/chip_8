require 'gosu'

module Chip8
  class Renderer < Gosu::Window
    WIDTH = 640
    HEIGHT = 320

    def initialize
      super(WIDTH, HEIGHT)
    end

    def clear
    end
  end
end
