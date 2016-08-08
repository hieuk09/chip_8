require 'chip_8/main'
require 'spec_helper'

describe Chip8::Main do
  let(:chip) { described_class.new }

  describe '#open' do
    it 'opens the rom' do
      rom_path = "roms/INVADERS"
      expect {
        chip.open(rom_path)
      }.to change { chip.memory[0x200 + 1] }
        .from(nil).to(37)
    end
  end

  describe '#start' do
    context 'when renderer is not available' do
      it 'raises error' do
        expect {
          chip.start
        }.to raise_error(Chip8::NoRendererError)
      end
    end

    context 'when renderer is available' do
      let(:renderer) { double('Renderer') }
      let(:chip) { described_class.new(renderer: renderer) }

      it 'starts the rom' do
        expect(renderer).to receive(:show)
        chip.start
      end
    end
  end
end
