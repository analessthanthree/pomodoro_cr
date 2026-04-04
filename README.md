# pomodoro_cr

A pomodoro timer written in Crystal

Features:
- No `tput`, uses ANSI escape sequences to create a basic TUI
- Snarky status messages (more coming soon...) to keep you on your toes
- Configurable via yaml (coming soon), via CLI, or during runtime
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

## Installation

- Clone this repo
- `crystal build --release src/pomodoro_cr.cr`
- Move, copy, or sym-link the resulting binary to your preferred `PATH` location (e.g. `~/.local/bin`)

## Usage

TODO: Write usage instructions here

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/your-github-user/pomodoro_cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [your-name-here](https://github.com/your-github-user) - creator and maintainer
