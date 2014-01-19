module BoshReleaseDiff::Comparators
  class Variations
    def self.from(items)
      new(items, nil, nil)
    end

    def initialize(items, parent, parent_index)
      @items = items
      @parent = parent
      @parent_index = parent_index
    end

    def shared_value(&blk)
      found = @items.compact.detect(&blk)
      blk.call(found) if found
    end

    def extract(&blk)
      @items.map(&blk).flatten
    end

    def break_down(&blk)
      self.class.new(@items.map(&blk), self, nil)
    end

    def break_down_flat(&blk)
      values = @items.map(&blk)
      sizes = values.map { |v| v.size }
      parent_index = lambda { |child_index| 
        total = 0
        sizes.each.with_index { |size, i| 
          return i if child_index < (total += size)
        }
        raise "Cannot determine parent index"
      }
      self.class.new(values.flatten, self, parent_index)
    end

    def each_with_context(&blk)
      @items.each.with_index do |item, i|
        blk.call(item, Context.new(i, self), i)
      end
    end

    class Context
      def initialize(index, variation)
        @index = index
        @variation = variation
      end

      def find_kind_of(klass_name)
        @variation.find_kind_of(@index, /::#{klass_name}$/)
      end

      def find_all
        @variation.find_all(@index)
      end
    end

    def find_kind_of(index, klass_name_regex)
      if klass && klass.name =~ klass_name_regex
        @items[index]
      elsif @parent
        index = @parent_index.call(index) if @parent_index
        @parent.find_kind_of(index, klass_name_regex)
      else
        nil
      end
    end

    def find_all(index)
      if @parent
        index = @parent_index.call(index) if @parent_index
        items = @parent.find_all(index)
      end
      [[@items[index], klass]] + (items || [])
    end

    private

    def klass
      @klass ||= shared_value(&:class)
    end
  end
end
