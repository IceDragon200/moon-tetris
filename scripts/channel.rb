class Channel
  def initialize
    @poll = []
  end

  def put(d)
    @poll.push d
  end

  alias :<< :put

  def pop
    @poll.pop
  end

  def empty?
    @poll.empty?
  end
end
