require "option_parser"
require "./config_helper.cr"
require "yaml"

module PomodoroCr
  include ConfigHelper
  class DefaultFileNotFound < Exception end
  class FileNotFound < Exception end

  class Configuration
    property work_duration : Time::Span?
    property short_break_duration : Time::Span?
    property long_break_duration : Time::Span?
    property long_break_frequency : UInt8?
    property messages : MotivationalMsgs

    @@base_path : Path =  Path["~/.config/pomodoro_cr"].expand(home: true)
    @@default_config_path : Path = @@base_path / "config.yaml"
    getter config_path : Path

    def initialize
      c_cli = parse_cli_args

      # De-nil the c_cli[:config_path] Path | Nil union type
      @config_path = c_cli[:config_path] || @@default_config_path

      c_yaml = load_yaml_config @config_path

      @work_duration = c_cli[:work_duration] \
      || c_yaml[:work_duration] || 25.minutes
      @short_break_duration = c_cli[:short_break_duration] \
      || c_yaml[:short_break_duration] || 5.minutes
      @long_break_duration = c_cli[:long_break_duration] \
      || c_yaml[:long_break_duration] || 15.minutes
      @long_break_frequency = c_cli[:long_break_frequency] \
      || c_yaml[:long_break_frequency] || 4_u8

      messages = c_cli[:polite_messages] ? POLITE_MESSAGES : DEFAULT_MESSAGES
      @messages = concat_messages messages, c_yaml[:messages]

      if c_cli[:dump_config]
        puts to_yaml
        exit 0
      end
    end

    def to_s(io)
      io << <<-CONFIG
      Configuration:
        Work Duration: #{@work_duration}
        Short Break Duration: #{@short_break_duration}
        Long Break Duration: #{@long_break_duration}
        Long Break Frequency: #{@long_break_frequency}
      CONFIG
    end

    def to_yaml
      {
        work_duration: @work_duration.as(Time::Span).minutes,
        short_break_duration: @short_break_duration.as(Time::Span).minutes,
        long_break_duration: @long_break_duration.as(Time::Span).minutes,
        long_break_frequency: @long_break_frequency,
        messages: @messages
      }.to_yaml
    end

    def concat_messages(m1 : MotivationalMsgs, m2 : MotivationalMsgs?)
      return m1 unless m2
      m1.each_key do |k|
        # De-nil the second set of messages using a tmp var
        if (tmp = m2[k])
          # The first set of messages will always at least have a default value, so we explicitly tell the compiler that we can de-nil it
          m1[k].as(Array(String)).concat tmp
        end
      end
      m1
    end

    def load_yaml_config(config_path : Path)
      unless File.file? config_path
        if config_path == @@default_config_path
          raise DefaultFileNotFound.new
        else
          raise FileNotFound.new("Configuration file #{config_path} not found. Exiting...")
        end
      end

      c = Config.from_yaml(File.read config_path)

      wd : Time::Span? = nil
      sbd : Time::Span? = nil
      lbd : Time::Span? = nil

      wd = if (tmp = c[:work_duration])
        tmp.minutes
      end

      sbd = if (tmp = c[:short_break_duration])
        tmp.minutes
      end

      lbd = if (tmp = c[:long_break_duration])
        tmp.minutes
      end

      {
        work_duration: wd,
        short_break_duration: sbd,
        long_break_duration: lbd,
        long_break_frequency: c[:long_break_frequency],
        messages: c[:messages]
      }
    rescue ex : DefaultFileNotFound
      {
        work_duration: nil,
        short_break_duration: nil,
        long_break_duration: nil,
        long_break_frequency: nil,
        messages: nil
      }
    rescue ex : FileNotFound
      puts ex
      exit 1
    rescue ex: YAML::ParseException
      puts "Failed to correctly parse yaml file #{config_path}. Exiting..."
      exit 1
    end

    def parse_cli_args
      work_duration : Time::Span? = nil
      short_break_duration : Time::Span? = nil
      long_break_duration : Time::Span? = nil
      long_break_frequency : UInt8? = nil
      config_path : Path? = nil
      dump_config = false
      polite_messages = false

      OptionParser.parse do |p|
        p.banner = "Usage: pomodoro_cr [opts]"
        p.on(
          "-w DUR",
          "--work-duration DUR",
          "Work duration (minutes)"
        ) do |dur|
            work_duration = dur.to_u8.minutes
        rescue ex : ArgumentError
          puts "Error: Argument '#{dur}' must be a positive integer"
          exit 1
        end

        p.on(
          "-s DUR",
          "--short-break-duration DUR",
          "Short break duration (minutes)"
        ) do |dur|
          short_break_duration = dur.to_u8.minutes
        rescue ex : ArgumentError
          puts "Error: Argument '#{dur}' must be a positive integer"
          exit 1
        end

        p.on(
          "-l DUR",
          "--long-break-duration DUR",
          "Long break duration (minutes)"
        ) do |dur|
          long_break_duration = dur.to_u8.minutes
        rescue ex : ArgumentError
          puts "Error: Argument '#{dur}' must be a positive integer"
          exit 1
        end

        p.on(
          "-f FREQ",
          "--long-break-frequency FREQ",
          "Long break frequency (every N pomodoros)"
        ) do |freq|
          long_break_frequency = freq.to_u8
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
            config_path = Path[path].expand(home: true)
        end

        p.on(
          "-d",
          "--dump-config",
          "Print working configuration to stdout and exit"
        ) { dump_config = true}

        p.on(
          "-p",
          "--polite-messages",
          "Use polite messages instead of the default snarky ones"
        ) { polite_messages = true }

        p.on(
          "-h",
          "--help",
          "Prints help message"
        ) do
          puts p
          exit 0
        end

        p.invalid_option do |flag|
          STDERR.puts "ERROR: #{flag} is not a valid option."
          STDERR.puts p
          exit(1)
        end
      end
      return {
        work_duration: work_duration,
        short_break_duration: short_break_duration,
        long_break_duration: long_break_duration,
        long_break_frequency: long_break_frequency,
        config_path: config_path,
        dump_config: dump_config,
        polite_messages: polite_messages
      }
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
end
