module MoonTetris
  module Rotation
    CW   = 90
    CCW  = 270
    FLIP = 180
  end

  module Difficulty
    EASY   = 0
    NORMAL = 1
    HARD   = 2
  end

  IGNORE = -1

  def self.calculate_table_bounds(table)
    # BUGGY, Needs fixing :/
    bounds = Moon::Rect.new(0xFFFF, 0xFFFF, -0xFFFF, -0xFFFF)
    table.each_with_xy do |n, x, y|
      if n != IGNORE
        bounds.x = x if x < bounds.x
        bounds.y = y if y < bounds.y
        bounds.w = x if x > bounds.x
        bounds.h = y if y > bounds.y
      end
    end
    bounds
  end

  class Block < Moon::DataModel::Metal
    field :data,     type: Moon::Table,   default: proc{|t|t.new(4, 4, default: IGNORE)}
    field :pivot,    type: Moon::Vector2, default: proc{|t|t.new(0, 0)}
    field :position, type: Moon::Vector2, default: proc{|t|t.new(0, 0)}
    field :bounds,   type: Moon::Rect,    default: proc{|t|t.new(0, 0, 4, 4)}
    field :can_flip, type: Boolean,       default: true

    def rotate(angle)
      self.data = data.rotate(angle) if can_flip
      calculate_bounds
    end

    def calculate_bounds
      self.bounds = Moon::Rect.new(0, 0, data.xsize, data.ysize)
      #self.bounds = MoonTetris.calculate_table_bounds(data)
    end

    def pbounds
      Moon::Rect.new(position.x + bounds.x, position.y + bounds.y, bounds.w, bounds.h)
    end

    def width
      data.xsize
    end

    def height
      data.ysize
    end
  end

  class BlockFactory < Moon::DataModel::Metal
    array :block_colors, type: Integer
    array :blocks,       type: Block
    field :difficulty,   type: Integer, default: Difficulty::NORMAL

    def post_init
      super
      self.block_colors = (0..24).to_a
      make_templates
    end

    def make_templates
      blocks.clear

      new_template '##' +
                   '##',
                   0, 0, 2, 2

      new_template '#' +
                   '#' +
                   '#' +
                   '#',
                   0, 0, 1, 4

      new_template '####',
                   0, 0, 4, 1

      if difficulty >= Difficulty::NORMAL
        new_template ' # ' +
                     '###',
                     0, 0, 3, 2

        new_template '# ' +
                     '# ' +
                     '##',
                     0, 0, 2, 3

        new_template ' #' +
                     ' #' +
                     '##',
                     0, 0, 2, 3
      end

      if difficulty == Difficulty::HARD
        new_template ' # ' +
                     ' # ' +
                     '###',
                     0, 0, 3, 3

        new_template ' # ' +
                     '###' +
                     ' # ',
                     0, 0, 3, 3

        new_template '###' +
                     ' # ' +
                     '###',
                     0, 0, 3, 3

        new_template ' ##' +
                     ' ##' +
                     '###',
                     0, 0, 3, 3

        new_template '## ' +
                     '## ' +
                     '###',
                     0, 0, 3, 3

        new_template '###' +
                     '# #' +
                     '###',
                     0, 0, 3, 3
      end
    end

    private def new_template(smap, *bounds)
      @ref ||= {
        ' ' => IGNORE,
        '#' => 0
      }
      r = Moon::Rect.new(*bounds)
      b = Block.new
      b.bounds = r
      b.data.resize(r.width.to_i, r.height.to_i)
      b.data.set_from_strmap(smap, @ref)
      blocks << b
      b
    end

    def new_block
      block = blocks.sample.copy
      block.data.replace(0, block_colors.sample)
      block
    end
  end

  class Playzone < Moon::DataModel::Metal
    field :data,   type: Moon::Table, default: proc{|t|t.new(10, 22, default: IGNORE)}
    field :bounds, type: Moon::Rect,  default: proc{|t|t.new(0, 0, 0, 0)}

    def calculate_bounds
      self.bounds = MoonTetris.calculate_table_bounds(data)
    end

    def width
      data.xsize
    end

    def height
      data.ysize
    end
  end

  class Stats < Moon::DataModel::Metal
    field :score,       type: Integer, default: 0
    field :block_count, type: Integer, default: 0
  end

  class Session < Moon::DataModel::Metal
    field :stats,         type: Stats,        default: proc{|t|t.new}
    field :block_factory, type: BlockFactory, default: proc{|t|t.new}
    field :active_block,  type: Block,        default: nil
    field :next_block,    type: Block,        default: nil
    field :playzone,      type: Playzone,     default: proc{|t|t.new}

    attr_accessor :reset_ch

    def start
      new_block
      new_block
    end

    def center_block(block)
      block.position.x = ((playzone.data.xsize - block.bounds.width) / 2).to_i
      block.position.y -= block.bounds.y2
      block
    end

    def new_block
      self.active_block = next_block
      self.next_block = center_block(block_factory.new_block)
    end

    def new_game
      self.stats = Stats.new
      self.block_factory = BlockFactory.new
      self.playzone = Playzone.new
      self.active_block = nil
      self.next_block = nil
      start
      reset_ch << true if reset_ch
    end
  end

  class Controller
    def initialize(session)
      @session = session
      @scheduler = Moon::Scheduler.new

      @job = @scheduler.every 0.15 do
        frame_update
      end
    end

    def place_block
      b = @session.active_block
      p = b.position

      @session.playzone.data.blit(b.data, p.x, p.y, b.data.rect) do |n, _, _|
        n != IGNORE
      end

      @session.new_block
      true
    end

    def check_collision
      b = @session.active_block
      bb = b.pbounds
      d = @session.playzone.data

      # if the block has reached the bottom, just place it
      if bb.y2 >= d.ysize
        #b.position.y -= 1
        #puts "BOTTOM COLLIDE!"
        return place_block
      end

      (b.data.ysize - 1).downto(0) do |y|
        b.data.xsize.times do |x|
          n = b.data[x, y]
          dx, dy = bb.x + x, bb.y + y
          if d.in_bounds?(dx, dy) && d[dx, dy] != IGNORE && n != IGNORE
            # move the block up space to avoid intersecting
            b.position.y -= 1
            #puts "#{[dx, dy]} BLOCK COLLIDE! #{bb.inspect}"
            return place_block
          end
        end
      end
    end

    def gameover
      @session.new_game
      true
    end

    def check_gameover
      d = @session.playzone.data

      2.times do |y|
        d.xsize.times do |x|
          return gameover if d[x, y] != IGNORE
        end
      end
      false
    end

    def check_line_clear
      d = @session.playzone.data
      marked = []
      (d.ysize).downto(0) do |y|
        clear_line = true
        d.xsize.times do |x|
          if d[x, y] == IGNORE
            clear_line = false
            break
          end
        end
        marked << y if clear_line
      end
      marked.each do |row|
        # row splice
        puts row
        d.fill_rect(0, row, d.xsize, 1, IGNORE)
        top = d.subsample(0, 0, d.xsize, row)
        d.fill_rect(0, 0, d.xsize, row, IGNORE)
        d.blit(top, 0, 1, 0, 0, top.xsize, top.ysize)
      end
    end

    def frame_update
      @session.active_block.position.y += 1
      check_gameover || check_line_clear if check_collision
    end

    def update(delta)
      @scheduler.update(delta)
    end

    def move_block(block, x, y)
      block.position.x = (block.position.x + x).clamp(0, @session.playzone.width - block.width)
      block.position.y += y
      if y != 0
        check_collision
      end
    end

    def setup_input(input)
      input.on :press, :left do
        move_block @session.active_block, -1, 0
      end

      input.on :press, :right do
        move_block @session.active_block, +1, 0
      end

      input.on :press, :down do
        move_block @session.active_block, 0, +1
      end

      input.on :press, :space do
        @session.active_block.rotate(90)
      end
    end
  end

  class ActiveBlockRenderer < Chipmap
    attr_reader :active_block

    def refresh_active_block
      self.position = @active_block.position.to_vec3 * cell_size
      self.data = @active_block.data
    end

    def active_block=(active_block)
      @active_block = active_block
      refresh_active_block
    end

    def update_content(delta)
      super
      refresh_active_block
    end
  end

  class View < Moon::RenderContainer
    attr_reader :session

    def init_from_options(options)
      super
      @session = options.fetch(:session)
    end

    def init_content
      super
      @spritesheet = Moon::Spritesheet.new('resources/blocks/block_16x16_007.png', 16, 16)
      @cell_size = @spritesheet.cell_size
      @playzone = Chipmap.new
      @playzone.spritesheet = @spritesheet
      @active_block = ActiveBlockRenderer.new
      @active_block.spritesheet = @spritesheet
      refresh_playzone
      refresh_active_block

      @reset_ch = Channel.new
      @session.reset_ch = @reset_ch

      @game_window = Moon::RenderContainer.new
      @game_window.add @playzone
      @game_window.add @active_block
      @game_window.position.x = ((Moon::Screen.width - @game_window.width) / 2).to_i
      @game_window.position.y -= @cell_size.y * 2
      add @game_window
    end

    def refresh_playzone
      @playzone.data = @session.playzone.data
    end

    def refresh_active_block
      @active_block.active_block = @session.active_block
    end

    def refresh
      refresh_playzone
    end

    def session=(session)
      @session = session
      refresh_playzone
    end

    def update_content(delta)
      refresh if @reset_ch.pop unless @reset_ch.empty?
      refresh_active_block
      super
    end

    def render_content(x, y, z, o)
      super
      @spritesheet.render(x + @game_window.x + @playzone.data.xsize * @cell_size.x,
                          y + @game_window.y + @playzone.data.ysize * @cell_size.y,
                          0,
                          1)
    end
  end

  class << self
    attr_accessor :session
  end
end
