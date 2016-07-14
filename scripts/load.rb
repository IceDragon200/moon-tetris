require 'scripts/std_ext'
require 'scripts/data_model_ext'
require 'scripts/buffer'
require 'scripts/chipmap'
require 'scripts/moon_tetris'
require 'scripts/input_trigger_patch'
require 'scripts/states'

MoonTetris.session = MoonTetris::Session.new
MoonTetris.session.new_game

def step(engine, delta)
  #@state ||= RendererWindowskinTest.new(engine)
  #@state ||= RendererTest.new(engine)
  @state ||= States::Game.new(engine)
  #@state ||= TilemapTest.new(engine)
  #@state ||= SpritesheetTest.new(engine)
  @state.update(delta)
end
