module BoshReleaseDiff::Comparators
  class Perms
    def initialize(edges)
      @edges = edges
    end

    def each(&blk)
      each_edge(@edges, &blk)
    end

    private

    def each_edge(edges, item_path=[], &blk)
      items, klass = edges[0]
      last_item = nil
      items.each_with_context do |item, context, i|
        obj = klass.new(*(item_path+[item]), i, last_item, context)
        blk.call(obj, item_path.size)
        each_edge(edges[1..-1], item_path+[item], &blk) if edges.size > 1
        last_item = item
      end
    end
  end
end
