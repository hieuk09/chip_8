module Chip8
  class Interpreter
    def initialize(chip)
      @chip = chip
    end

    def run(renderer)
      chip.step += 1

      if chip.step % 2 == 0 && chip.delay_timer > 0
        chip.delay_timer -= 1
      end

      if chip.program_counter >= 0x1000
        chip.running = false
        return
      end
      opcode = (chip.memory[chip.program_counter] << 8) | chip.memory[chip.program_counter + 1]
      increase_program_counter

      sub_routine_pointer = opcode & 0x0FFF
      compared_value = opcode & 0x00FF
      register_index_1 = (opcode & 0x0F00) >> 8
      register_index_2 = (opcode & 0x00F0) >> 4

      case opcode & 0xF000
      when 0x0000
        case opcode
        when 0x00E0
          chip.display = chip.new_matrix
          chip.draw_flag = true
        when 0x00EE
          chip.program_counter = chip.stack.pop
        end

      when 0x1000 # JMP
        chip.program_counter = sub_routine_pointer

      when 0x2000 # CALL
        chip.stack.push(chip.program_counter)
        chip.program_counter = sub_routine_pointer

      when 0x3000 # SE - skip if equal
        if chip.registers[register_index_1] == compared_value
          increase_program_counter
        end

      when 0x4000 # SNE - skip if not equal
        if chip.registers[register_index_1] != compared_value
          increase_program_counter
        end

      when 0x5000 # SE Vx Vy - skip if registry equal
        if chip.registers[register_index_1] == chip.registers[register_index_2]
          increase_program_counter
        end

      when 0x6000 # load to register
        chip.registers[register_index_1] = compared_value

      when 0x7000 # add value
        chip.registers[register_index_1] = (chip.registers[register_index_1] + compared_value) % 256

      when 0x8000
        case opcode & 0x000F
        when 0x0000
          chip.registers[register_index_1] = chip.registers[register_index_2]

        when 0x0001
          chip.registers[register_index_1] |= chip.registers[register_index_2]

        when 0x0002
          chip.registers[register_index_1] &= chip.registers[register_index_2]

        when 0x0003
          chip.registers[register_index_1] ^= chip.registers[register_index_2]

        when 0x0004
          chip.registers[register_index_1] += chip.registers[register_index_2]

          if chip.registers[register_index_1] > 255
            chip.registers[0xF] = 1
            chip.registers[register_index_1] %= 256
          else
            chip.registers[0xF] = 0
          end

        when 0x0005
          if chip.registers[register_index_1] > chip.registers[register_index_2]
            chip.registers[0xF] = 1
          else
            chip.registers[0xF] = 0
          end

          chip.registers[register_index_1] -= chip.registers[register_index_2]
          chip.registers[register_index_1] %= 256

        when 0x0006
          chip.registers[0xF] = chip.registers[register_index_1] % 2
          chip.registers[register_index_1] /= 2

        when 0x0007
          if chip.registers[register_index_2] > chip.registers[register_index_1]
            chip.registers[0xF] = 1
          else
            chip.registers[0xF] = 0
          end

          chip.registers[register_index_1] = chip.registers[register_index_2] - chip.registers[register_index_1]
          chip.registers[register_index_1] %= 256

        when 0x000E
          chip.registers[register_index_1] *= 2
          chip.registers[0xF] = chip.registers[register_index_1] / 256
          chip.registers[register_index_1] %= 256
        end
      when 0x9000 # skip if not equal with register
        if chip.registers[register_index_1] != chip.registers[register_index_2]
          increase_program_counter
        end

      when 0xA000 # LD I, addr
        chip.register_i = sub_routine_pointer

      when 0xB000
        chip.program_counter = sub_routine_pointer + chip.registers[0]

      when 0xC000
        chip.registers[register_index_1] = rand(0..255) & compared_value
      when 0xD000
        chip.registers[0xF] = 0
        height = opcode & 0x000F
        x = chip.registers[register_index_1]
        y = chip.registers[register_index_2]

        (0..height-1).each do |i|
          data = chip.memory[chip.register_i + i]

          (0..7).each do |j|
            if (data & 0x80) > 0
              # set pixel
              a = x + j
              b = y + i

              if a >= Chip8::Main::WIDTH
                a -= Chip8::Main::WIDTH
              elsif a < 0
                a += Chip8::Main::WIDTH
              end

              if b >= Chip8::Main::HEIGHT
                b -= Chip8::Main::HEIGHT
              elsif b < 0
                b += Chip8::Main::HEIGHT
              end

              value = chip.display[a, b] ^ 1
              chip.display.send(:'[]=', a, b, value)

              if chip.display[a, b] == 0
                chip.registers[0xF] = 1
              end
            end
            data <<= 1
          end

          chip.draw_flag = true
        end

        renderer.update_buffer(chip.display)

      when 0xE000
        key = chip.registers[(opcode & 0x0F00) >> 8]

        case opcode & 0x00FF
        when 0x009E
          if chip.keys[key] != 0
            increase_program_counter
          end
        when 0x00A1
          if chip.keys[key] == 0
            increase_program_counter
          end
        end

      when 0xF000
        case opcode & 0x00FF
        when 0x0007
          chip.registers[register_index_1] = chip.delay_timer

        when 0x000A
          # not handle yet

        when 0x0015
          chip.delay_timer = chip.registers[register_index_1]
        when 0x0018
          # not handle yet

        when 0x001E
          chip.register_i += chip.registers[register_index_1]

        when 0x0029
          chip.register_i = chip.registers[register_index_1] * 5

        when 0x0033
          value = chip.registers[register_index_1]

          (2..0).each do |i|
            chip.memory[chip.register_i + i] = value % 10
            value /= 10
          end

        when 0x0055
          (0..register_index_1).each do |i|
            chip.memory[chip.register_i + i] = chip.registers[i]
          end
        when 0x0065
          (0..register_index_1).each do |i|
            chip.registers[i] = chip.memory[chip.register_i + i]
          end
        end
      end
    end

    private

    attr_reader :chip

    def increase_program_counter
      chip.program_counter += 2
    end
  end
end
