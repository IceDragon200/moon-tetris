require 'scripts/std_ext'
require 'scripts/data_model_ext'
require 'scripts/channel'
require 'scripts/chipmap'
require 'scripts/moon_tetris'
require 'scripts/input_trigger_patch'
require 'scripts/state_middleware'
require 'scripts/states'

MoonTetris.session = MoonTetris::Session.new
MoonTetris.session.new_game
State.push States::Game
