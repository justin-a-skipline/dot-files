define Color
  ColorRegular
end
document Color
Sets text color using terminal escape sequences.
Effect is undone by colored prompt.
Usage: Color[COLOR = Regular]
Available colors:
LightGray
White
Black
DarkGray
Red
LightRed
Green
LightGreen
Brown
Yellow
Blue
LightBlue
Magenta
LightMagenta
Cyan
LightCyan
Regular
end

define _startTermEscape
  echo \001
end

define _endTermEscape
  echo \002
end

define ColorLightGray
  _startTermEscape
  echo \033[0;37m
  _endTermEscape
end

define ColorWhite
  _startTermEscape
  echo \033[1;37m
  _endTermEscape
end

define ColorBlack
  _startTermEscape
  echo \033[0;30m
  _endTermEscape
end

define ColorDarkGray
  _startTermEscape
  echo \033[1;30m
  _endTermEscape
end

define ColorLightRed
  _startTermEscape
  echo \033[0;31m
  _endTermEscape
end

define ColorGreen
  _startTermEscape
  echo \033[0;32m
  _endTermEscape
end

define ColorLightGreen
  _startTermEscape
  echo \033[1;32m
  _endTermEscape
end

define ColorBrown
  _startTermEscape
  echo \033[0;33m
  _endTermEscape
end

define ColorYellow
  _startTermEscape
  echo \033[1;33m
  _endTermEscape
end

define ColorBlue
  _startTermEscape
  echo \033[1;34m
  _endTermEscape
end

define ColorLightblue
  _startTermEscape
  echo \033[0;34m
  _endTermEscape
end

define ColorMagenta
  _startTermEscape
  echo \033[0;35m
  _endTermEscape
end

define ColorLightMagenta
  _startTermEscape
  echo \033[1;35m
  _endTermEscape
end

define ColorCyan
  _startTermEscape
  echo \033[0;36m
  _endTermEscape
end

define ColorLightCyan
  _startTermEscape
  echo \033[1;36m
  _endTermEscape
end

define ColorRed
  _startTermEscape
  echo \033[1;31m
  _endTermEscape
end

define ColorRegular
  _startTermEscape
  echo \033[0m
  _endTermEscape
end

