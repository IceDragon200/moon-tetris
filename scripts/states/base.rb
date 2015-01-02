module States
  class Base < ::State
    include StateMiddlewarable
  end
end
