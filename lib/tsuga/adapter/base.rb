module Tsuga
  module Adapter
    class Base
      def records
        raise NotImplementedError
      end

      def clusters
        raise NotImplementedError
      end
    end
  end
end