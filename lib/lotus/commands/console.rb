module Lotus
  module Commands
    class Console
      module Methods
        def reload!
          puts 'Reloading...'
          Kernel.exec "#{$0} console"
        end
      end

      ENGINES = {
        'pry'  => 'Pry',
        'ripl' => 'Ripl',
        'irb'  => 'IRB'
      }.freeze

      attr_reader :options

      def initialize(environment)
        @environment = environment
        @options     = environment.to_options
      end

      def start
        # Clear out ARGV so Pry/IRB don't attempt to parse the rest
        ARGV.shift until ARGV.empty?
        require @environment.env_config.to_s

        # Add convenience methods to the main:Object binding
        TOPLEVEL_BINDING.eval('self').send(:include, Methods)
        Lotus::Application.preload!

        engine.start
      end

      def engine
        load_engine options.fetch(:engine) { engine_lookup }
      end

      private

      def engine_lookup
        (ENGINES.find { |_, klass| Object.const_defined?(klass) } || default_engine).first
      end

      def default_engine
        ENGINES.to_a.last
      end

      def load_engine(engine)
        require engine
      rescue LoadError
      ensure
        return Object.const_get(
          ENGINES.fetch(engine) {
            raise ArgumentError.new("Unknown console engine: #{ engine }")
          }
        )
      end
    end
  end
end
