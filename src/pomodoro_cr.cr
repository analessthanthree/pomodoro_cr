# TODO: Write documentation for `PomodoroCr`
module PomodoroCr
  VERSION = "0.1.0"

  enum State
    PAUSE
    NEW_POMODORO
    WORK
    NEW_SHORT_BREAK
    SHORT_BREAK
    NEW_LONG_BREAK
    LONG_BREAK
  end

  class Pomodoro

    @time_remaining : Time::Span
    @dt : Time::Span
    @state : State

    def initialize()

      @refresh_period = (1.0/60.0).seconds
      # @refresh_period = 1.seconds
      @time_remaining = 60.seconds
      @time = Time.instant
      @dt = 0.seconds

      @input = IO::FileDescriptor.from_stdio(0)
      @input.read_timeout = @refresh_period

      @state = State::PAUSE

      @quit = false

    end

    def enable_alt_screen
      print "\e[?1049h"
    end

    def disable_alt_screen
      print "\e[?1049l"
    end

    def update_timer
      @dt = Time.instant - @time
      @time_remaining -= @dt unless @state == State::PAUSE
      @time = Time.instant
    end

    def erase_reset_cursor
      print "\e[2J\e[H"
    end

    def print_header
      print "----------------------------------------------------------------------------\n\r"
      print "Pomodoro Timer!    [ #{@state} ]\n\r"
      print "----------------------------------------------------------------------------\n\r"
    end

    def print_timer
      print "#{@time_remaining}\n\r"
    end

    def print_message(msg : NamedTuple(type: String, value: String)?)
      print "Message: #{msg}\n\r"
    end

    def print_footer
      print "----------------------------------------------------------------------------\n\r"
      print "[Enter] pause/unpause    [s] skip    [q] quit    [c] configure\n\r"
      print "----------------------------------------------------------------------------\n\r"
    end

    def run
      c = ' '
      enable_alt_screen
      @input.raw!
      until @quit
        # Read user input
        c = begin
          @input.read_char
        rescue ex : IO::TimeoutError
          nil
        end

        # Process user input
        case c
        when '\r'
          msg = {type: "Enter", value: "true"}
        when 's'
          msg = {type: "Skip", value: "true"}
          @state += 1
        when 'c'
          msg = {type: "Configure", value: "true"}
        when 'q'
          msg = {type: "quit", value: "true"}
          @quit = true
        when nil
          msg = {type: "Nil", value: "nil"}
        else
          msg = {type: "Other", value: c.to_s}
        end

        # Output
        erase_reset_cursor
        update_timer
        print_header
        print_timer
        print_message msg
        print_footer

      end
    ensure
      disable_alt_screen
      @input.cooked!
    end
  end

  pomo = Pomodoro.new
  pomo.run
end
