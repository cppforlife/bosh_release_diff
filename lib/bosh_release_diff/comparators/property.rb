require "bosh_release_diff/comparators/perms"

module BoshReleaseDiff::Comparators
  # Compares multiple release properties to multiple dep man properties
  class Property
    def initialize(rel_properties, dep_man_properties, logger)
      @rel_properties = rel_properties
      @dep_man_properties = dep_man_properties
      @logger = logger
    end

    def name
      @rel_properties.shared_value(&:name)
    end

    def description
      @rel_properties.shared_value(&:description)
    end

    def changes
      Perms.new([
        [@rel_properties,     ReleasePropertyChange], 
        [@dep_man_properties, DeploymentManifestPropertyChange],
      ])
    end

    class ReleasePropertyChange
      def initialize(rel_prop, index, prev_rel_prop, context)
        @rel_prop = rel_prop
        @prev_rel_prop = prev_rel_prop
        @index = index
        @context = context
      end

      # Considered changed when release property is 
      # removed/added or its default value does not match.
      def changes
        changes = []

        if @prev_rel_prop && !@rel_prop
          changes << :property_removed
        elsif !@prev_rel_prop && @rel_prop
          changes << :property_added unless @index.zero?
        end

        if (a = @prev_rel_prop) && (b = @rel_prop)
          if a.has_default_value? && !b.has_default_value?
            changes << :property_default_removed
          elsif !a.has_default_value? && b.has_default_value?
            changes << :property_default_added
          end

          if a.has_default_value? && b.has_default_value?
            if a.default_value != b.default_value
              changes << :property_default_value
            end
          end
        end

        changes
      end

      def description
        str = "[#{@context.find_kind_of('Release').contextual_name}] "

        if @prev_rel_prop && @rel_prop
          str += "present"
        elsif @prev_rel_prop && !@rel_prop
          # Potentially breaking custom tuned deployment
          # since user might have configured this property.
          # (@index.zero? is not possible since prev_rel_prop=nil)
          str += "removed".make_yellow
        elsif !@prev_rel_prop && @rel_prop
          str += @index.zero? ? "present" : "added"
        else # !@prev_rel_prop && !@rel_prop
          str += "not present"
        end

        if @rel_prop
          if @rel_prop.has_default_value?
            str += "; defaults to #{@rel_prop.default_value.inspect}"
          else
            str += "; " + "no default".make_yellow
          end
        end

        str
      end
    end

    class DeploymentManifestPropertyChange
      def initialize(rel_prop, dep_man_prop, index, prev_dep_man_prop, context)
        @rel_prop = rel_prop
        @dep_man_prop = dep_man_prop
        @prev_dep_man_prop = prev_dep_man_prop
        @index = index
        @context = context
      end

      # Considered changed when dep manifest property is 
      # removed/added or its value does not match.
      def changes
        changes = []

        if @prev_dep_man_prop && !@dep_man_prop
          changes << :dep_man_property_removed
        elsif !@prev_dep_man_prop && @dep_man_prop
          changes << :dep_man_property_added unless @index.zero?
        end

        if (a = @prev_dep_man_prop) && (b = @dep_man_prop)
          changes << :dep_man_property_value if a.value != b.value
        end

        changes
      end

      def description
        # context = @context.find_all # useful for debugging
        context = "#{@context.find_kind_of('Job').contextual_name}@" + 
                  "#{@context.find_kind_of('DeploymentManifest').contextual_name}"

        str = "[#{context}] "

        if @dep_man_prop
          str += "set to #{@dep_man_prop.value.inspect}"
          if !@rel_prop
            # Dep man specifies property but 
            # it is not used by the job template.
            str += "; " + "ignored".make_red
          end
        else
          if @rel_prop && !@rel_prop.has_default_value?
            # Dep man does not specify property and
            # job template does not specify a default value.
            str += "not set".make_red
          else
            str += "not set"
          end
        end

        if @rel_prop && @dep_man_prop
          if !@rel_prop.has_default_value?
            # str += "; no default"
          elsif @dep_man_prop.value == @rel_prop.default_value
            # Purposefully setting dep man property 
            # to a value that is a current job template default?
            str += "; " + "duplicating default".make_yellow
          elsif @dep_man_prop.value != @rel_prop.default_value
            str += "; overriding default"
          end
        end

        str
      end
    end
  end
end
