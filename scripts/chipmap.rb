class Chipmap < Moon::RenderContext
  IGNORE = -1

  attr_reader :data        # Moon::Table
  attr_reader :spritesheet

  def data=(data)
    @data = data
    @width = nil
    @height = nil
  end

  def spritesheet=(s)
    @spritesheet = s
    @cell_size = nil
    @width = nil
    @height = nil
  end

  def cell_size
    @cell_size ||= @spritesheet.cell_size
  end

  def width
    @width ||= cell_size.x * data.xsize
  end

  def height
    @height ||= cell_size.y * data.ysize
  end

  def render_content(x, y, z)
    cw, ch = @spritesheet.w, @spritesheet.h
    @data.iter.each_with_xy do |n, fx, fy|
      next if n == IGNORE
      sx, sy, sz = x + cw * fx, y + ch * fy, z
      #puts [sx, sy, sz].inspect
      @spritesheet.render sx, sy, sz, n
    end
    super
  end
end
