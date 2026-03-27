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
      @input_controller = Channel(Char?).new
      @output_controller = Channel(NamedTuple(type: String, value: String)).new

      @refresh_period = (1.0/60.0).seconds
      @refresh_period = 1.seconds
      @time_remaining = 60.seconds
      @time = Time.instant
      @dt = 0.seconds

      @input = IO::FileDescriptor.from_stdio(0)
      @input.read_timeout = @refresh_period

      @state = State::PAUSE

      @quit = Channel(Bool).new

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

    def input_loop
      c = ' '
      @input.raw do
        until c == 'q'
          begin
            c = @input.read_char
            @input_controller.send c
          rescue ex : IO::TimeoutError
            @input_controller.send nil
          end
        end
      end
    end

    def output_loop
      loop do

        msg = @output_controller.receive
        break if msg == {type: "quit", value: "true"}

        erase_reset_cursor
        update_timer
        print_header
        print_timer
        print_message msg
        print_footer
      end
    end

    # Blocks with @input_controller.receive, processes messages, send to output, loop
    def controller_loop
      loop do
        input = @input_controller.receive

        case input
        when '\r'
          msg = {type: "Enter", value: "true"}
        when 's'
          msg = {type: "Skip", value: "true"}
          @state += 1
        when 'c'
          msg = {type: "Configure", value: "true"}
        when 'q'
          msg = {type: "quit", value: "true"}
          @output_controller.send msg
          @quit.send true
          break
        when nil
          msg = {type: "Nil", value: "nil"}
        else
          msg = {type: "Other", value: input.to_s}
        end
        @output_controller.send msg
      end
    end

    def run
      enable_alt_screen

      spawn { input_loop }
      spawn { output_loop }
      spawn { controller_loop }

      # Blocks main fiber until user quits
      @quit.receive
    ensure
      disable_alt_screen
    end
  end

  pomo = Pomodoro.new
  pomo.run
end
