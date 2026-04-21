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

  POLITE_MESSAGES = {
    new_pomodoro: ["Enter to start"],
    work: ["Let's get to work!"],
    new_short_break: ["Time for a short break."],
    short_break: ["See you soon!"],
    new_long_break: ["Time for a long break."],
    long_break: ["See you soon!"]
  }

  DEFAULT_MESSAGES =  {
    "new_pomodoro":  [
      "Enter to start",
      "Let's get ready to rumble!",
      "Another day, another pomodoro.",
      "Did you hydrate or naw?",
      "Five more minutes, mom!"
    ],

    "work":  [
      "LOL you're working, loser!",
      "Are we there yet?",
      "Go go go go!",
      "You've got this bb!"
    ],

    "new_short_break":  [
      "Ready for a break already?",
      "Phew! Time for a breather.",
      "Another one down!",
      "Yippeeeeee!"
    ],

    "short_break":  [
      "Go grab some coffee!",
      "Oooooh big stretch!",
      "Drink some water!",
      "Stand up, do some squats or something.",
    ],

    "new_long_break":  [
      "You've been working hard haven't you?",
      "Do *not*, under any circumstances, doom scroll during your break or so help me!",
      "Scribbily, griddily, bibbily, doo! I have a brand new long break for you!",
      "Am I really making myself come up with another one of these? Come on now."
    ],

    "long_break":  [
      "Have a break. You've earned it!",
      "Remember to take care of yourself!",
      "Time for a quick walk.",
      "My boss makes a dollar..."
    ]
  }

end
