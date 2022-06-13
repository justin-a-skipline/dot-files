set history filename ~/.gdb_history
set history save on
set pagination off
set print entry-values compact
set print symbol on
set print pretty on
set print demangle on
set print asm-demangle on
set disassembly-flavor intel
set output-radix 10
set confirm off
set prompt ================================================================================\n(gdb) 

set $_list_on_next = 1
set $_list_on_step = 1
set $_list_on_finish = 1
set $_list_on_break = 1
set $_list_on_up = 1
set $_list_on_down = 1
set $_list_on_until = 1

set $print_symbol_filename = 1

define SetListLocals
  if $argc > 0
    set $list_locals = $arg0
  end
end
document SetListLocals
Sets whether to run info locals on Context display.
This might be a slow call in C++ with references to
class objects because they are expanded rather than treated
like a pointer by gdb.
Usage: SilenceOff
end
SetListLocals 0

define SetPrintSymbolFilename
  if $arg0 > 0
    set print symbol-filename on
  else
    set print symbol-filename off
  end
end
SetPrintSymbolFilename $print_symbol_filename

set $_listsize = 9
set listsize $_listsize

define SilenceOn
  set logging off
  set logging overwrite on
  set logging file ~/gdbsilence.txt
  set logging redirect on
  set logging on
end
document SilenceOn
Redirects command output to log file, "silencing" commands.
Usage: SilenceOff
end

define SilenceOff
  set logging off
  set logging overwrite off
  set logging redirect off
  set logging on
end
document SilenceOff
Stops redirecting command output to log file.
Usage: SilenceOff
end

define LoggingOn
  set logging off
  set logging overwrite off
  set logging file ~/gdb-log.txt
  set logging redirect on
  set logging on
end
document LoggingOn
Redirects output to log file (~/gdb-log.txt).
May interact with other commands because of
the overlap with SilenceOn and SilenceOff used
to get nice output at breakpoints. Is safe to
use and then turn off within a breakpoint however.
Usage: LoggingOn
end

define LoggingOff
  set logging off
  set logging file ~/gdb-log.txt
  set logging redirect off
  set logging off
end
document LoggingOff
Turns off logging to ~/gdb-log.txt
end

define LoggingTimestampBlocking
  shell date +%s%N >> ~/gdb-log.txt
end
document LoggingTimestampBlocking
Causes shell to append nanosecond precision timestamp
to ~/gdb-log.txt. This means there will
be a delay in program execution while command
finishes. Measured with "time":
real    0m0.006s
user    0m0.001s
sys     0m0.000s
end

define LoggingTimestampNonBlocking
  shell date +%s%N >> ~/gdb-log.txt &
end
document LoggingTimestampNonBlocking
Causes shell to append nanosecond precision timestamp
to ~/gdb-log.txt. This means there will
be a delay in program execution while command
finishes. Measured with "time":
real    0m0.001s
user    0m0.000s
sys     0m0.001s
end

define LoggingTimestamp
LoggingTimestampNonBlocking
end
document LoggingTimestamp
Causes shell to append nanosecond precision timestamp
to ~/gdb-log.txt. Defaults to non-blocking.
If seeing corrupted output, consider using
LoggingTimestampBlocking instead.
end

define LogClear
  shell > ~/gdb-log.txt
end
document LogClear
Empties log file of all contents. DESTRUCTIVE
end

define GraphClear
printf "\r\rRTGRAPH clear_graph\n"
end
document GraphClear
Clears graph
end

define GraphPause
printf "\r\rRTGRAPH pause_graph 1\n"
end
document GraphPause
Clears graph
end

define GraphResume
printf "\r\rRTGRAPH pause_graph 0\n"
end
document GraphPause
Clears graph
end

define GraphValue
  if $argc == 2
    printf "\r\rRTGRAPH add %s %f\n", $arg0, (float)$arg1
  end
  if $argc == 3
    printf "\r\rRTGRAPH add %s %f %f\n", $arg0, (float)$arg2, (float)$arg1
  end
end
document GraphValue
Graphs value presented in form:
"name" y_value
"name" x_value y_value
end

define GraphSingleValueWithTimeStamp
  if $argc == 2
    printf "\r\rRTGRAPH add_time %s %f\n",$arg0, (float)$arg1
  end
end
document GraphSingleValueWithTimeStamp
Graphs value presented in form:
"name" y_value
adds timestamp as offset from first reading
end

define AsciiChar
set $_c=*(unsigned char *)($arg0)
if ( $_c < 0x20 || $_c > 0x7E )
printf "."
else
printf "%c", $_c
end
end
document AsciiChar
Print the ASCII value of arg0 or '.' if value is unprintable
end
 
define _HexQuad
printf "%02X %02X %02X %02X  %02X %02X %02X %02X",                          \
               *(unsigned char*)($arg0), *(unsigned char*)($arg0 + 1),      \
               *(unsigned char*)($arg0 + 2), *(unsigned char*)($arg0 + 3),  \
               *(unsigned char*)($arg0 + 4), *(unsigned char*)($arg0 + 5),  \
               *(unsigned char*)($arg0 + 6), *(unsigned char*)($arg0 + 7)
end
document _HexQuad
Print eight hexadecimal bytes starting at arg0
Usage: _HexQuad address
end

define _AsciiQuad
AsciiChar ($arg0)
AsciiChar ($arg0+1)
AsciiChar ($arg0+2)
AsciiChar ($arg0+3)
AsciiChar ($arg0+4)
AsciiChar ($arg0+5)
AsciiChar ($arg0+6)
AsciiChar ($arg0+7)
end
document _AsciiQuad
Print eight Ascii bytes starting at arg0
Usage: _AsciiQuad address
end
 
define _HexDumpLine
printf "%08X : ", $arg0
_HexQuad $arg0
printf "  "
_HexQuad ($arg0+8)
printf " "
_AsciiQuad $arg0
_AsciiQuad ($arg0+8)
printf "\n"
end
document _HexDumpLine
Display a 16-byte hex/ASCII dump of arg0
Usage: _HexDumpLine address
end
 
define HexDump
  if $argc == 0
      HexDump $addr $prevHexDumpCount
  else
    if $argc == 1
      HexDump $arg0 4
    else
      set $_i=0
      set $prevHexDumpCount=$arg1
      set $addr=(void *)$arg0
      while ( $_i < $arg1 )
        _HexDumpLine $addr
        set $addr=$addr+16
        set $_i++
      end
    end
  end
end
document HexDump
Display arg1 * 16 number of bytes of memory at address arg0
Usage: HexDump address [num rows = 4]
end

define DisassembleSource
  set print symbol-filename off
  if $argc == 0
    set $_lines = 8
  else
    set $_lines = $arg0
  end

  printf "-----------------------------------REGISTERS------------------------------------\n"
  info registers
  printf "----------------------------------DISASSEMBLY-----------------------------------\n"
  SilenceOn
  # Be sure to include previous line just to maintain context while stepping
  info line *($pc - 4)
  SilenceOff
  disassemble /sr $_,($pc+(4*$_lines))
  SetPrintSymbolFilename $print_symbol_filename
end
document DisassembleSource
Disassembles current context plus next num instructions, including source.
Usage: Disassemble [num instructions = 8]
end

define DisassembleRaw
  set print symbol-filename off
  if $argc == 0
    set $_lines = 8
  else
    set $_lines = $arg0
  end

  printf "----------------------------------DISASSEMBLY-----------------------------------\n"
  disas/r $pc,+32
  printf "-----------------------------------REGISTERS------------------------------------\n"
  info registers
  SetPrintSymbolFilename $print_symbol_filename
end
document DisassembleRaw
Disassembles current context plus next num instructions, raw instructions only.
Usage: Disassemble [num instructions = 8]
end

define _MarkLine
  printf "~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ \n"
end

define ListSource
  if $argc > 0
    set $_ListSource_offset = 0
    set $_ListSource_location = $arg0
    if $argc > 1
      set $_ListSource_offset = $arg1
    end
  end
  printf "-----------------------------------ARGS-----------------------------------------\n"
  info args
  printf "-----------------------------------LOCALS---------------------------------------\n"
  if $list_locals > 0
    info locals
  end
  SilenceOn
  set listsize 1
  if $argc > 0
    list *($_ListSource_location + $_ListSource_offset)
  else
    frame
    list
  end
  SilenceOff
  printf "-----------------------------------LISTING--------------------------------------\n"
  set listsize 7
  list -
  set listsize 1
  _MarkLine
  list
  _MarkLine
  set listsize 10
  list
  set listsize $_listsize
  printf "---------------------------------END LISTING------------------------------------\n"
end
document ListSource
Prints listing of code with line being executed highlighted.
Address offset should be set to zero when examining random addresses or
before first instruction is executed like in resetHandler.
Address is offset by four by default to account for pipelining unless the variable is
overwritten.
Usage: ListSource [address = (as reported by frame)] [offset = 0]
end


define Context
  printf "-----------------------------------FRAME----------------------------------------\n"
  frame
  ListSource
end
document Context
Display various program execution information.
end

define hook-stop
end
document hook-stop
Hook to run when execution stops.
end

define iskip
  set $pc=$pc+4
  DisassembleRaw
end
document iskip
Jump past 4 byte instruction.
end

define ListOnBreak
  if $_list_on_break > 0
    commands
      ListSource
    end
  end
end

define b
  break $arg0
  ListOnBreak
end

define tb
  tbreak $arg0
  ListOnBreak
end

define n
  next
  if $_list_on_next > 0
    ListSource
  end
end
define rn
  reverse-next
  if $_list_on_next > 0
    ListSource
  end
end

define s
  step
  if $_list_on_step > 0
    ListSource
  end
end
define rs
  reverse-step
  if $_list_on_step > 0
    ListSource
  end
end

define si
  stepi
  DisassembleRaw
end

define ni
  nexti
  DisassembleRaw
end

define f
  finish
  if $_list_on_finish > 0
    ListSource
  end
end
define rf
  reverse-finish
  if $_list_on_finish > 0
    ListSource
  end
end

define u
  up
  if $_list_on_up > 0
    ListSource
  end
end

define rc
  reverse-continue
end

define d
  down
  if $_list_on_down > 0
    ListSource
  end
end

define un
  if $argc > 0
    until $arg0
  else
    until
  end
  if $_list_on_until > 0
    ListSource
  end
end

set $_bp1 = 0
set $_bp2 = 0
set $_bp3 = 0
set $_bp4 = 0
set $_lastbp = 0
define DependentBreakpoints
  if $argc < 2
    printf "2 breakpoints needed\n"
  else
    if $argc >= 5
      printf "TODO: Implement 5 dependent breakpoints\n"
    else
      if $argc >= 2
        set $_bp1 = $arg0
        set $_bp2 = $arg1
        set $_lastbp = $_bp2
        disable $_bp2
      end

      if $argc >= 3
        set $_bp3 = $arg2
        set $_lastbp = $_bp3
        disable $_bp3
      end

      if $argc >= 4
        set $_bp4 = $arg3
        set $_lastbp = $_bp4
        disable $_bp4
      end


      enable $_bp1

      if $argc >= 2
        commands $_bp1
          disable $_bp1
          enable $_bp2
          c
        end
        commands $_bp2
          disable $_bp2
          enable $_bp3
          c
        end
      end

      if $argc >= 3
        commands $_bp3
          disable $_bp3
          enable $_bp4
          c
        end
      end

      commands $_lastbp
        DependentBreakPointsRestart
        Context
      end
    end
  end
end

define DependentBreakPointsRestart
  disable $_lastbp
  enable $_bp1
end
document DependentBreakPointsRestart
Sets up conditions for last breakpoint easily
so you can override actions on last breakpoint
and have the chain restart. Meant to be used
inside of a chain of commands.
Example:
commands $_lastbp
DependentBreakPointsRestart
InsertCustomCommandsHere
end

# from http://silmor.de/qtstuff.printqstring.php
define Qt5PrintQString
  set $d=$arg0.d
  printf "(Qt5 QString)0x%x length=%i: \"",&$arg0,$d->size
  set $i=0
  set $ca=(const ushort*)(((const char*)$d)+$d->offset)
  while $i < $d->size
    set $c=$ca[$i++]
    if $c < 32 || $c > 127
      printf "\\u%04x", $c
    else
      printf "%c" , (char)$c
    end
  end
  printf "\"\n"
end
