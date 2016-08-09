require 'matrix'

module Chip8
  class Main
    attr_reader :memory, :registers, :stack,
      :display, :width, :height
    attr_accessor :draw_flag, :program_counter, :register_i, :running,
      :delay_timer

    def initialize
      @memory = Array.new(0x1000)
      @registers = Array.new(16)
      @stack = Array.new
      @program_counter = 0
      @draw_flag = false
      @register_i = nil
      @delay_timer = 0
      @running = false
      @width = 64
      @height = 32
      @display = Matrix.build(width, height) { 0 }

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
        registers[i] = 0
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
      if program_counter >= 0x1000
        self.running = false
        return
      end
      opcode = (memory[program_counter] << 8) | memory[program_counter + 1]
      self.program_counter += 2

      sub_routine_pointer = opcode & 0x0FFF
      compared_value = opcode & 0x00FF
      register_index_1 = (opcode & 0x0F00) >> 8
      register_index_2 = (opcode & 0x00F0) >> 4

      case opcode & 0xF000
      when 0x0000
        case opcode
        when 0x00E0
          # clear
        when 0x00EE
          self.program_counter = stack.pop
        end

      when 0x1000 # JMP
        self.program_counter = sub_routine_pointer

      when 0x2000 # CALL
        stack.push(program_counter)
        self.program_counter = sub_routine_pointer

      when 0x3000 # SE - skip if equal
        if registers[register_index_1] == compared_value
          self.program_counter += 2
        end

      when 0x4000 # SNE - skip if not equal
        if registers[register_index_1] != compared_value
          self.program_counter += 2
        end

      when 0x5000 # SE Vx Vy - skip if registry equal
        if registers[register_index_1] == registers[register_index_2]
          self.program_counter += 2
        end

      when 0x6000 # load to register
        registers[register_index_1] = compared_value

      when 0x7000 # add value
        registers[register_index_1] = (registers[register_index_1] + compared_value) % 256

      when 0x8000
        case opcode & 0x000F
        when 0x0000
          registers[register_index_1] = registers[register_index_2]

        when 0x0001
          registers[register_index_1] |= registers[register_index_2]

        when 0x0002
          registers[register_index_1] &= registers[register_index_2]

        when 0x0003
          registers[register_index_1] ^= registers[register_index_2]

        when 0x0004
          registers[register_index_1] += registers[register_index_2]

          if registers[register_index_1] > 255
            registers[0xF] = 1
            registers[register_index_1] %= 256
          else
            registers[0xF] = 0
          end

        when 0x0005
          if registers[register_index_1] > registers[register_index_2]
            registers[0xF] = 1
          else
            registers[0xF] = 0
          end

          registers[register_index_1] -= registers[register_index_2]
          registers[register_index_1] %= 256

        when 0x0006
          registers[0xF] = registers[register_index_1] % 2
          registers[register_index_1] /= 2

        when 0x0007
          if registers[register_index_2] > registers[register_index_1]
            registers[0xF] = 1
          else
            registers[0xF] = 0
          end

          registers[register_index_1] = registers[register_index_2] - registers[register_index_1]
          registers[register_index_1] %= 256

        when 0x000E
          registers[register_index_1] *= 2
          registers[0xF] = registers[register_index_1] / 256
          registers[register_index_1] %= 256
        end
      when 0x9000 # skip if not equal with register
        if registers[register_index_1] != registers[register_index_2]
          self.program_counter += 2
        end

      when 0xA000 # LD I, addr
        self.register_i = sub_routine_pointer

      when 0xB000
        self.program_counter = sub_routine_pointer + registers[0]

      when 0xC000
        registers[register_index_1] = rand(0, 255) & compared_value
      when 0xD000
        registers[0xF] = 0
        height = opcode & 0x000F
        x = registers[register_index_1]
        y = registers[register_index_2]

        (0..height-1).each do |i|
          data = memory[register_i + i]

          (0..7).each do |j|
            if (data & 0x80) > 0
              # set pixel
              a = x + j
              b = y + i

              if a > width
                a -= width
              elsif a < 0
                a += width
              end

              if b > height
                b -= height
              elsif b < 0
                b += height
              end

              value = display[a, b] ^ 1
              display.send(:'[]=', a, b, value)

              registers[0xF] = 1
            end
            data <<= 1
          end

          self.draw_flag = true
        end

      when 0xE000
        # not handle yet

      when 0xF000
        case opcode & 0x00FF
        when 0x0007
          registers[register_index_1] = delay_timer

        when 0x000A
          # not handle yet

        when 0x0015
          self.delay_timer = registers[register_index_1]
        when 0x0018
          # not handle yet

        when 0x001E
          self.register_i += registers[register_index_1]
          self.register_i %= 256

        when 0x0029
          self.register_i = registers[register_index_1] * 5
          self.register_i %= 256

        when 0x0033
          value = registers[register_index_1]

          (2..0).each do |i|
            memory[register_i + i] = value % 10
            value /= 10
          end

        when 0x0055
          (0..register_index_1).each do |i|
            memory[register_i + i] = registers[i]
          end
        when 0x0065
          (0..register_index_1).each do |i|
            register[i] = memory[register_i + i]
          end
        end
      end
    end
  end
end
