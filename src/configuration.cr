require "option_parser"
require "./config_helper.cr"
require "yaml"

module PomodoroCr

  include ConfigHelper

  class Configuration
    property work_duration : Time::Span?
    property short_break_duration : Time::Span?
    property long_break_duration : Time::Span?
    property long_break_frequency : UInt8?
    property messages : MotivationalMsgs?

    def initialize(
      *,
      work_duration : Time::Span? = nil,
      short_break_duration : Time::Span? = nil,
      long_break_duration : Time::Span? = nil,
      long_break_frequency : UInt8? = nil,
      messages : MotivationalMsgs? = nil
    )
      @work_duration = work_duration
      @short_break_duration = short_break_duration
      @long_break_duration = long_break_duration
      @long_break_frequency = long_break_frequency
      @messages = messages
    end

    # Default values
    def initialize
      @work_duration = 25.minutes
      @short_break_duration = 5.minutes
      @long_break_duration = 15.minutes
      @long_break_frequency = 4
      @messages = DEFAULT_MESSAGES
    end

    # Merges self with another Configuration. Non-nil properties present in `new_config` override those found in self.
    # Returns a new Configuration, i.e. leaves self untouched
    def merge(new_config c : Configuration)
      wd = c.work_duration || self.work_duration
      sbd = c.short_break_duration || self.short_break_duration
      lbd = c.long_break_duration || self.long_break_duration
      lbf = c.long_break_frequency || self.long_break_frequency
      msgs = c.messages || self.messages
      Configuration.new(
        work_duration: wd,
        short_break_duration: sbd,
        long_break_duration: lbd,
        long_break_frequency: lbf,
        messages: msgs
      )
    end

    # Ensure that work, short_break, long_break duration and long_break_frequency are all set
    def valid?
      ! @work_duration.nil? &&
      ! @short_break_duration.nil? &&
      ! @long_break_duration.nil? &&
      ! @long_break_frequency.nil? &&
      ! @messages.nil?
    end
  end

  class CLIConfig < Configuration
    @@base_path : Path =  Path["~/.config/pomodoro_cr"].expand(home: true)
    getter config_path : Path?

    def initialize
      @messages = DEFAULT_MESSAGES

      OptionParser.parse do |p|
        p.banner = "Usage: pomodoro_cr [opts]"

        p.on(
          "-w DUR",
          "--work-duration DUR",
          "Work duration (minutes)"
        ) do |dur|
            @work_duration = dur.to_u8.minutes
        rescue ex : ArgumentError
          puts "Error: Argument '#{dur}' must be a positive integer"
          exit 1
        end

        p.on(
          "-s DUR",
          "--short-break-duration DUR",
          "Short break duration (minutes)"
        ) do |dur|
          @short_break_duration = dur.to_u8.minutes
        rescue ex : ArgumentError
          puts "Error: Argument '#{dur}' must be a positive integer"
          exit 1
        end

        p.on(
          "-l DUR",
          "--long-break-duration DUR",
          "Long break duration (minutes)"
        ) do |dur|
          @long_break_duration = dur.to_u8.minutes
        rescue ex : ArgumentError
          puts "Error: Argument '#{dur}' must be a positive integer"
          exit 1
        end

        p.on(
          "-f FREQ",
          "--long-break-frequency FREQ",
          "Long break frequency (every N pomodoros)"
        ) do |freq|
          @long_break_frequency = freq.to_u8
        rescue ex : ArgumentError
          puts "Error: Argument '#{freq}' must be a positive integer"
          exit 1
        end

        # Parse the file path, but we don't actually parse the file here
        p.on(
          "-c PATH",
          "--config-path PATH",
          "Path to YAML file containing YAML pomodoro configuration (default: ~/.config/pomodoro_cr/config.yaml)"
        ) do |path|
            @config_path = Path[path].expand(home: true)
        end

        p.on(
          "-h",
          "--help",
          "Prints help message"
        ) { puts p }

        p.invalid_option do |flag|
          STDERR.puts "ERROR: #{flag} is not a valid option."
          STDERR.puts p
          exit(1)
        end
      end
    end

  end

  class YAMLConfig < Configuration

    class DefaultFileNotFound < Exception
    end

    # Default values
    @@base_path = Path["~/.config/pomodoro_cr"].expand(home: true)
    getter config_path : Path = @@base_path / "config.yaml"

    # Load default config
    def initialize(dummy : Nil)
      raise DefaultFileNotFound.new unless File.file? @config_path
      load_config @config_path
    rescue ex : DefaultFileNotFound
    end

    # Load user defined config at config_path
    def initialize(config_path : Path | String)
      @config_path = Path[config_path]
      load_config @config_path
    end

    def load_config(config_path : Path)
      c = Config.from_yaml(File.read config_path)

      wd = c[:work_duration]
      sbd = c[:short_break_duration]
      lbd = c[:long_break_duration]

      @work_duration = wd.minutes if wd
      @short_break_duration = sbd.minutes if sbd
      @long_break_duration = lbd.minutes if lbd
      @long_break_frequency = c[:long_break_frequency]
      @messages = c[:messages]
    end

  end

  # Defaults
  default_config = Configuration.new

  # Overrides
  cli_overrides = CLIConfig.new

  # From config file
  yaml_config = YAMLConfig.new cli_overrides.config_path

  config = (default_config.merge yaml_config).merge cli_overrides

  pp default_config
  pp yaml_config
  pp cli_overrides
  pp config.valid?

end
