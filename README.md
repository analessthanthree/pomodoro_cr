# pomodoro_cr

A pomodoro timer written in Crystal

```
----------------------------------------------------------------------
Pomodoro Timer!
----------------------------------------------------------------------
Current: [ NEW_POMODORO ]
Next:    [ WORK ]
----------------------------------------------------------------------
Pomodoros Completed: 0
----------------------------------------------------------------------
Time Remaining: 00:25:00
Pomo Buddy Says: "Let's get ready to rumble!"
----------------------------------------------------------------------
[Enter] start    [s] skip    [q] quit    [c] configure
----------------------------------------------------------------------
```

Features:
- No `tput`, uses ANSI escape sequences to create a basic TUI
- Snarky status messages to keep you on your toes
- Configurable via yaml, via CLI, or during runtime
  - Pomodoro duration
  - Short break duration
  - Long break duration
  - Long break frequency
  - Status messages
- Alert/BEL sound when time is up
- Pausing and skipping supported

What it's missing:
- Test coverage lol
- A fully featured TUI: no auto-resizing, no wrapping, etc.
- Motivation to do work not included

## What is Pomodoro

The [pomodoro technique](https://en.wikipedia.org/wiki/Pomodoro_Technique) is a method for time management that's helped me personally. It typically consists of cycles of 25 minutes of work followed by a 5 minute short break, with a 15 minute long break every 4 cycles, referred to as pomodoros.

## Installation

- Clone this repo
- `crystal build --release src/pomodoro_cr.cr`
- Move, copy, or sym-link the resulting binary to your preferred `PATH` location (e.g. `~/.local/bin`)

## Usage

```
./pomodoro_cr -h
Usage: pomodoro_cr [opts]
    -w DUR, --work-duration DUR      Work duration (minutes)
    -s DUR, --short-break-duration DUR
                                     Short break duration (minutes)
    -l DUR, --long-break-duration DUR
                                     Long break duration (minutes)
    -f FREQ, --long-break-frequency FREQ
                                     Long break frequency (every N pomodoros)
    -c PATH, --config-path PATH      Path to YAML file containing YAML pomodoro configuration (default: ~/.config/pomodoro_cr/config.yaml)
    -d, --dump-config                Print working configuration to stdout and exit
    -p, --polite-messages            Use polite messages instead of the default snarky ones
    -h, --help                       Prints help message
```

## Configuration

Configuration is done via a YAML file, searched for at `~/.config/pomodoro_cr/config.yaml` by default. See `example_config.yaml` for an example. YAML config can be overwritten using CLI options as shown above. Default values are:

- `work-duration`: 25 minutes
- `short-break-duration`: 5 minutes
- `long-break-duration`: 15 minutes
- `long-break-frequency`: every 4 pomodoros

To create a new config:

```bash
# bash
mkdir -p ~/.config/pomodoro_cr
./pomodoro_cr -d > ~/.config/pomodoro_cr
```

### Snarky Messages

Your snarky co-worker "Pomo Buddy" will print out a random message for the current "phase" of your pomodoro cycle. These are defined in `./src/config_helper.cr`. Change them at will before compiling. Optionally, you can also define your own messages in `config.yaml` that will be appended to the default snarky or "polite" messages.

## Contributing

1. Fork it (<https://github.com/your-github-user/pomodoro_cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [ana](https://github.com/analessthanthree) - creator and maintainer
