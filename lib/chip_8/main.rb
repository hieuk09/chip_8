require_relative 'interpreter'
require 'matrix'
require 'gosu'

module Chip8
  class Main
    attr_reader :memory, :registers, :stack, :keys
    attr_accessor :draw_flag, :program_counter, :register_i, :running,
      :delay_timer, :display, :step

    WIDTH = 64
    HEIGHT = 32

    KEY_MAP = {
      '1' => 0x1,
      '2' => 0x2,
      '3' => 0x3,
      '4' => 0xC,
      'q' => 0x4,
      'w' => 0x5,
      'e' => 0x6,
      'r' => 0xD,
      'a' => 0x7,
      's' => 0x8,
      'd' => 0x9,
      'f' => 0xE,
      'z' => 0xA,
      'x' => 0x0,
      'c' => 0xB,
      'v' => 0xF
    }

    def initialize
      @memory = Array.new(0x1000)
      @registers = Array.new(16)
      @keys = Array.new(16)
      @stack = Array.new
      @program_counter = 0x200
      @draw_flag = false
      @register_i = nil
      @delay_timer = 0
      @running = false
      @display = new_matrix
      @step = 0

      (0..0x1000 - 1).each do |i|
        memory[i] = 0
      end

      hex_chars = [
        0xF0, 0x90, 0x90, 0x90, 0xF0, # 0
        0x20, 0x60, 0x20, 0x20, 0x70, # 1
        0xF0, 0x10, 0xF0, 0x80, 0xF0, # 2
        0xF0, 0x10, 0xF0, 0x10, 0xF0, # 3
        0x90, 0x90, 0xF0, 0x10, 0x10, # 4
        0xF0, 0x80, 0xF0, 0x10, 0xF0, # 5
        0xF0, 0x80, 0xF0, 0x90, 0xF0, # 6
        0xF0, 0x10, 0x20, 0x40, 0x40, # 7
        0xF0, 0x90, 0xF0, 0x90, 0xF0, # 8
        0xF0, 0x90, 0xF0, 0x10, 0xF0, # 9
        0xF0, 0x90, 0xF0, 0x90, 0x90, # A
        0xE0, 0x90, 0xE0, 0x90, 0xE0, # B
        0xF0, 0x80, 0x80, 0x80, 0xF0, # C
        0xE0, 0x90, 0x90, 0x90, 0xE0, # D
        0xF0, 0x80, 0xF0, 0x80, 0xF0, # E
        0xF0, 0x80, 0xF0, 0x80, 0x80 # F
      ]

      (0..hex_chars.length - 1).each do |i|
        memory[i] = hex_chars[i]
      end

      (0..15).each do |i|
        keys[i] = registers[i] = 0
      end
    end

    def open(rom_path)
      File.open(rom_path) do |file|
        data = file.read
        data.each_byte.each_with_index do |byte, index|
          memory[index + 0x200] = byte
        end
      end
    end

    def start
      self.running = true
    end

    def run
      interpreter.run
    end

    def press(key)
      key_char = Gosu.button_id_to_char(key)
      return unless key_char
      button_name = KEY_MAP[key_char]
      return unless button_name
      keys[button_name] = 1
    end

    def release(key)
      key_char = Gosu.button_id_to_char(key)
      return unless key_char
      button_name = KEY_MAP[key_char]
      return unless button_name
      keys[button_name] = 0
    end

    def new_matrix
      Matrix.build(WIDTH, HEIGHT) { 0 }
    end

    private

    def interpreter
      @interpreter ||= Chip8::Interpreter.new(self)
    end
  end
end
