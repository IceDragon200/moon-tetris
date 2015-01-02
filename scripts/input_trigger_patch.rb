module Moon
  module Input
    @channels = []

    def self.register(channel)
      @channels.push channel
    end

    def self.unregister(channel)
      @channels.delete channel
    end

    def self.trigger(event)
      @channels.each do |channel|
        channel.trigger event
      end
    end
  end
end
