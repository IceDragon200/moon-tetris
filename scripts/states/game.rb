module States
  class Game < Base
    middleware InputMiddleware

    def init
      super
      @session = MoonTetris.session
      @controller = MoonTetris::Controller.new(@session)
      @view = MoonTetris::View.new(session: @session).tag('game.view')
      @controller.setup_input(middleware(InputMiddleware).handle)
    end

    def update(delta)
      super
      @controller.update(delta)
      @view.update(delta)
      render
    end

    def render
      @view.render
    end
  end
end
