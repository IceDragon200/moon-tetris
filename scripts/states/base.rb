module States
  class Base < ::State
    include StateMiddlewarable

    attr_reader :input

    def init
      super
      @input = Moon::Input::Observer.new
    end
  end
end
