set $ENABLE_COLOR = 0

define SetEnableColor
  if $argc == 0
    set $ENABLE_COLOR = 1
  else
    set $ENABLE_COLOR = $arg0
  end
  if $ENABLE_COLOR > 0
    set prompt \001\033[0;31m\002================================================================================\n(gdb) \001\033[0m\002
  else
    set prompt ================================================================================\n(gdb) 
  end
end
document SetEnableColor
SetEnableColor - Enables or disables color in outputs
Usage: SetEnableColor [bool=1]
end

define ClearEnableColor
  SetEnableColor 0
end
document ClearEnableColor
ClearEnableColor - Disables color in outputs
Usage: ClearEnableColor
end

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
  if $ENABLE_COLOR > 0
    _startTermEscape
    echo \033[0;37m
    _endTermEscape
  end
end

define ColorWhite
  if $ENABLE_COLOR > 0
    _startTermEscape
    echo \033[1;37m
    _endTermEscape
  end
end

define ColorBlack
  if $ENABLE_COLOR > 0
    _startTermEscape
    echo \033[0;30m
    _endTermEscape
  end
end

define ColorDarkGray
  if $ENABLE_COLOR > 0
    _startTermEscape
    echo \033[1;30m
    _endTermEscape
  end
end

define ColorLightRed
  if $ENABLE_COLOR > 0
    _startTermEscape
    echo \033[0;31m
    _endTermEscape
  end
end

define ColorGreen
  if $ENABLE_COLOR > 0
    _startTermEscape
    echo \033[0;32m
    _endTermEscape
  end
end

define ColorLightGreen
  if $ENABLE_COLOR > 0
    _startTermEscape
    echo \033[1;32m
    _endTermEscape
  end
end

define ColorBrown
  if $ENABLE_COLOR > 0
    _startTermEscape
    echo \033[0;33m
    _endTermEscape
  end
end

define ColorYellow
  if $ENABLE_COLOR > 0
    _startTermEscape
    echo \033[1;33m
    _endTermEscape
  end
end

define ColorBlue
  if $ENABLE_COLOR > 0
    _startTermEscape
    echo \033[1;34m
    _endTermEscape
  end
end

define ColorLightblue
  if $ENABLE_COLOR > 0
    _startTermEscape
    echo \033[0;34m
    _endTermEscape
  end
end

define ColorMagenta
  if $ENABLE_COLOR > 0
    _startTermEscape
    echo \033[0;35m
    _endTermEscape
  end
end

define ColorLightMagenta
  if $ENABLE_COLOR > 0
    _startTermEscape
    echo \033[1;35m
    _endTermEscape
  end
end

define ColorCyan
  if $ENABLE_COLOR > 0
    _startTermEscape
    echo \033[0;36m
    _endTermEscape
  end
end

define ColorLightCyan
  if $ENABLE_COLOR > 0
    _startTermEscape
    echo \033[1;36m
    _endTermEscape
  end
end

define ColorRed
  if $ENABLE_COLOR > 0
    _startTermEscape
    echo \033[1;31m
    _endTermEscape
  end
end

define ColorRegular
  if $ENABLE_COLOR > 0
    _startTermEscape
    echo \033[0m
    _endTermEscape
  end
end

