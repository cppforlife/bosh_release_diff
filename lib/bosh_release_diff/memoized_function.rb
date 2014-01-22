module BoshReleaseDiff
  module MemoizedFunction
    def memoized_function(func_name)
      new_func_name = "#{func_name}_not_memoized"
      alias_method(new_func_name, func_name)
      private(new_func_name)

      define_method(func_name) do
        unless result = instance_variable_get("@#{func_name}")
          result = send(new_func_name)
          instance_variable_set("@#{func_name}", result)
        end
        result
      end
    end
  end
end
