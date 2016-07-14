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
  @state_manager ||= begin
    sm = Moon::StateManager.new(engine)
    sm.push States::Game
    sm
  end
  @state_manager.step(delta)
end
