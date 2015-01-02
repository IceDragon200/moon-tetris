module Moon
  class Rect
    def rotate(angle)
      case angle % 360
      when 0
        dup
      when 90, 270
        self.class.new(x, y, h, w)
      when 180
        self.class.new(x, y, w, h)
      else
        raise RuntimeError, "unsupported rotation angle #{angle}"
      end
    end
  end
end
