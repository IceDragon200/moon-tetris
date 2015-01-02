module States
  class Title < Base
    middleware InputMiddleware

    def init
      super
      @input = middleware(InputMiddleware).handle
      @input.on :any do |e|
        puts e
      end
    end
  end
end
