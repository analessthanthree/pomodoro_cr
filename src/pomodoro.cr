module PomodoroCr
  enum State
    NEW_POMODORO
    WORK
    NEW_SHORT_BREAK
    SHORT_BREAK
    NEW_LONG_BREAK
    LONG_BREAK
  end

  class Pomodoro

    @@horizontal_line = "-" * 70 + "\n\r"

    property time_remaining : Time::Span
    property? paused : Bool
    @dt : Time::Span
    @long_break_frequency : UInt8

    def initialize()

      @refresh_period = (1.0/60.0).seconds
      # @refresh_period = 1.seconds
      @time_remaining = 60.seconds
      @time = Time.instant
      @dt = 0.seconds

      @input = IO::FileDescriptor.from_stdio(0)
      @input.read_timeout = @refresh_period

      @state = State::NEW_POMODORO
      @enter_action = "start"
      @paused = true

      @completed_work = 0
      @long_break_frequency = 4
      @work_duration = 25.minutes
      @short_break_duration = 5.minutes
      @long_break_duration = 15.minutes

      reset_timer @work_duration

      @quit = false

    end

    def enable_alt_screen
      print "\e[?1049h"
    end

    def disable_alt_screen
      print "\e[?1049l"
    end

    def erase_screen
      print "\e[2J"
    end

    def reset_cursor
      print "\e[H"
    end

    def print_bell
      print "\a"
    end

    def update_timer
      @dt = Time.instant - @time
      @time_remaining -= @dt unless paused?
      @time = Time.instant
    end

    def reset_timer(duration : Time::Span)
      @time_remaining = duration
    end

    # Returns the next state, but does not change it
    def next_state
      return case @state
      when .new_pomodoro? then State::WORK
      when .short_break?, .long_break? then State::NEW_POMODORO
      when .new_short_break? then State::SHORT_BREAK
      when .new_long_break? then State::LONG_BREAK
      when .work?
        (@completed_work + 1) % @long_break_frequency == 0 ? State::NEW_LONG_BREAK : State::NEW_SHORT_BREAK
      else @state
      end
    end

    # Actually advances the state
    def advance_state
      @state = next_state
      @enter_action = enter_action
      case @state
      when .new_pomodoro?
        @paused = true
        reset_timer @work_duration
      when .work?
        @paused = false
      when .new_short_break?
        @completed_work += 1
        @paused = true
        reset_timer @short_break_duration
      when .short_break?
        @paused = false
      when .new_long_break?
        @completed_work += 1
        @paused = true
        reset_timer @long_break_duration
      when .long_break?
        @paused = false
      end
    end

    def handle_enter
      case @state
      when .new_pomodoro?, .new_short_break?, .new_long_break?
        advance_state
      else
        @paused = ! paused?
      end
    end

    def enter_action
      case @state
      when .new_pomodoro?, .new_short_break?, .new_long_break?
        "start"
      else
        "pause/unpause"
      end
    end

    def print_header
      print @@horizontal_line
      print "Pomodoro Timer!\n\r"
      print @@horizontal_line
      print "Current: [ #{@state} ]\n\r"
      print "Next:    [ #{next_state} ]\n\r"
      print @@horizontal_line
      print "Pomodoros Completed: #{@completed_work}\n\r"
      print @@horizontal_line
    end

    def print_timer
      print "Time Remaining: #{@time_remaining}\n\r"
    end

    def print_message
      # Craft msg based on state
      msg = case @state
      when .new_pomodoro?
        "Enter to start"
      when .work?
        "LOL you're working loser"
      when .new_short_break?
        "Ready for a break already?"
      when .short_break?
        "Go make coffee or some shit"
      when .new_long_break?
        "Damn you really out here working, huh?"
      when .long_break?
        "Boop boop boop"
      end
      print "Message: #{msg}\n\r"
    end

    def print_footer
      print @@horizontal_line
      print "[Enter] #{@enter_action}    [s] skip    [q] quit    [c] configure\n\r"
      print @@horizontal_line
    end

    def get_user_input
      @input.read_char
    rescue ex : IO::TimeoutError
      nil
    end

    def get_user_input(&)
      yield get_user_input
    end

    def get_new_config(kind : String, unit : String)
      print "New #{kind} duration (#{unit}): "
      config = (gets chomp = true) || "nil"
      config.to_u8
    rescue ex
      puts "#{ex}, try again..."
      get_new_config kind, unit
    end

    def configure
      erase_screen
      reset_cursor
      @input.cooked do
        print @@horizontal_line
        puts "Pomodoro configuration"
        print @@horizontal_line

        puts <<-CONFIG
        Current configuration:
          Work duration: #{@work_duration}
          Short break duration: #{@short_break_duration}
          Long break duration: #{@long_break_duration}
          Long break frequency: #{@long_break_frequency}
        CONFIG
        print @@horizontal_line

        work_duration = get_new_config("work", "minutes").minutes
        short_break_duration = get_new_config("short break", "minutes").minutes
        long_break_duration = get_new_config("long break", "minutes").minutes
        long_break_frequency = get_new_config("long break frequency", "every N pomodoros")
        print @@horizontal_line

        puts <<-CONFIG
        New configuration:
          Work duration: #{work_duration}
          Short break duration: #{short_break_duration}
          Long break duration: #{long_break_duration}
          Long break frequency: #{long_break_frequency}
        CONFIG
        print @@horizontal_line

        puts "Accept new configuration?"
        print "This will reset your current timer to the new time: [y/N]: "
        if (gets chomp = true) == "y"
          puts "Setting new configuration..."
          @work_duration = work_duration
          @short_break_duration = short_break_duration
          @long_break_duration = long_break_duration
          @long_break_frequency = long_break_frequency

          case @state
          when .work? then reset_timer @work_duration
          when .short_break? then reset_timer @short_break_duration
          when .long_break? then reset_timer @long_break_duration
          end
        else
          puts "Discarding new configuration..."
        end
        sleep 1.seconds
      end
    end

    def handle_user_input(c : Char?)
      # Process user input
      case c
      when '\r'
        # Behavior of "Enter" depends on the state
        handle_enter
      when 's'
        advance_state
      when 'c'
        configure
      when 'q'
        @quit = true
      else
      end
    end

    def run
      enable_alt_screen
      @input.raw!
      until @quit

        if @time_remaining < 0.seconds
          print_bell
          advance_state
        end

        get_user_input do |c|
          handle_user_input c
        end

        update_timer

        erase_screen
        reset_cursor
        print_header
        print_timer
        print_message
        print_footer
      end
    ensure
      disable_alt_screen
      @input.cooked!
    end
  end
end
