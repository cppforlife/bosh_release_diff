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
      def initialize(current_rel_prop, index, prev_rel_prop, context)
        @current_rel_prop = current_rel_prop
        @index = index
        @prev_rel_prop = prev_rel_prop
        @context = context
      end

      def description
        str = "[#{@context.find_kind_of('Release').contextual_name}] "

        if @prev_rel_prop && @current_rel_prop
          str += "present"
        elsif @prev_rel_prop && !@current_rel_prop
          # Potentially breaking custom tuned deployment
          # since user might have configured this property.
          str += @index.zero? ? "not present" : "removed".make_yellow
        elsif !@prev_rel_prop && @current_rel_prop
          str += @index.zero? ? "present" : "added"
        else # !@prev_rel_prop && !@current_rel_prop
          str += "not present"
        end

        if @current_rel_prop
          if @current_rel_prop.has_default_value?
            str += "; defaults to #{@current_rel_prop.default_value.inspect}"
          else
            str += "; " + "no default".make_yellow
          end
        end

        str
      end
    end

    class DeploymentManifestPropertyChange
      def initialize(current_rel_prop, dep_man_prop, index, last_dep_man_property, context)
        @current_rel_prop = current_rel_prop
        @dep_man_prop = dep_man_prop
        @context = context
      end

      def description
        # context = @context.find_all # useful for debugging
        context = "#{@context.find_kind_of('Job').contextual_name}@" + 
                  "#{@context.find_kind_of('DeploymentManifest').contextual_name}"

        str = "[#{context}] "

        if @dep_man_prop
          str += "set to #{@dep_man_prop.value.inspect}"
          if !@current_rel_prop
            # Dep man specifies property but 
            # it is not used by the job template.
            str += "; " + "ignored".make_red
          end
        else
          if @current_rel_prop && !@current_rel_prop.has_default_value?
            # Dep man does not specify property and
            # job template does not specify a default value.
            str += "not set".make_red
          else
            str += "not set"
          end
        end

        if @current_rel_prop && @dep_man_prop
          if !@current_rel_prop.has_default_value?
            # str += "; no default"
          elsif @dep_man_prop.value == @current_rel_prop.default_value
            # Purposefully setting dep man property 
            # to a value that is a current job template default?
            str += "; " + "duplicating default".make_yellow
          elsif @dep_man_prop.value != @current_rel_prop.default_value
            str += "; overriding default"
          end
        end

        str
      end
    end
  end
end
