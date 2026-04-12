module ConfigHelper

  alias MotivationalMsgs = NamedTuple(
    new_pomodoro: Array(String)?,
    work: Array(String)?,
    new_short_break: Array(String)?,
    short_break: Array(String)?,
    new_long_break: Array(String)?,
    long_break: Array(String)?
  )

  alias Config = NamedTuple(
    work_duration: UInt8?,
    short_break_duration: UInt8?,
    long_break_duration: UInt8?,
    long_break_frequency: UInt8?,
    messages: MotivationalMsgs?
  )

#   alias MotivationalMsgs = Hash(String, Array(String))

  DEFAULT_MESSAGES =  {
    "new_pomodoro":  [
      "Enter to start",
      "Let's get ready to rumble!",
      "Another day, another pomodoro.",
      "Did you hydrate or naw?"
    ],

    "work":  [
      "LOL you're working, loser!"
    ],

    "new_short_break":  [
      "Ready for a break already?"
    ],

    "short_break":  [
      "Go grab some coffee or something"
    ],

    "new_long_break":  [
      "You've been working hard haven't you?"
    ],

    "long_break":  [
      "Have a break. You've earned it!"
    ]
  }

end
