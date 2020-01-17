set history filename ~/.gdb_history
set history save on
set pagination off
set prompt ================================================================================\n(gdb) 
set print entry-values compact
set print symbol on
set print pretty on

set $SHOW_CONTEXT = 0
set $listsize = 9
set listsize $listsize

define SilenceOn
  set logging off
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
  set logging redirect off
  set logging on
end
document SilenceOff
Stops redirecting command output to log file.
Usage: SilenceOff
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
  if $argc == 1
    HexDump $arg0 4
  else
    set $_i=0
    set $addr=(void *)$arg0
    while ( $_i < $arg1 )
    _HexDumpLine $addr
    set $addr=$addr+16
    set $_i++
    end
  end
end
document HexDump
Display arg1 * 16 number of bytes of memory at address arg0
Usage: HexDump address [num rows = 4]
end

define Disassemble
  if $argc == 0
    Disassemble 8
  else
    disassemble /sr *$pc,+(4*$arg0)
  end
end
document Disassemble
Disassembles next n chunks of 4 bytes after $pc
Usage: Disassemble [num instructions = 8]
end

define ListSource
  SilenceOn
  set listsize 1
  list *$pc
  SilenceOff
  set listsize 5
  list -
  set listsize 1
  printf "-------------------------------------------------\n"
  list
  printf "-------------------------------------------------\n"
  set listsize 5
  list
  set listsize $listsize
end


define Context
  printf "----------------REGISTERS------------------------\n"
  info registers
  printf "----------------ARGS-----------------------------\n"
  info args
  printf "----------------LOCALS---------------------------\n"
  info locals
  printf "----------------LISTING--------------------------\n"
  ListSource
  printf "-------------------------------------------------\n"
end
document Context
Display various program execution information.
end

define hook-stop
end
document hook-stop
Hook to run when execution stops.
end
