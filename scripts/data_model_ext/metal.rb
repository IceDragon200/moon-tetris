module Moon
  module DataModel
    class Metal
      def copy
        self.class.load export
      end
    end
  end
end
