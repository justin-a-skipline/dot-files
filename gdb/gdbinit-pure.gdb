set history filename ~/.gdb_history
set history save on
set pagination off
set print entry-values compact
set print symbol on
set print pretty on
set print demangle on
set print asm-demangle on
set disassembly-flavor intel
set output-radix 0x10
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
  info locals
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
        disable $_lastbp
        enable $_bp1
        Context
      end
    end
  end
end
