#
# it2check
#
# Checks if the terminal emulator is iTerm2.  This is a port of the bundled
# bash shell script `it2check` that is shipped as part of the iTerm2 
# application.
#
# Published at: https://github.com/nugget/dotfiles/fish/functions/it2check.fish
# Original script: https://iterm2.com/utilities/it2check
#
# (c) Copyright 2018 David McNett.  All Rights Reserved.
#

function it2check --description "Check if we are in an iTerm2 shell"
    if not status --is-interactive
        # If we're not in an interactive shell, don't do any magic iTerm stuff
        return 1
    else 
        function _read_bytes --argument-names numbytes
            dd bs=1 count=$numbytes 2>/dev/null
        end

        function _read_dsr
            set spam (_read_bytes 2)
            set byte (_read_bytes 1)

            while test "$byte" != "n"
                set dsr "$dsr$byte"
                set byte (_read_bytes 1)
            end

            echo -n $dsr
        end

        # Enter raw mode and turn off echo so the terminal and I can chat quietly.
        stty -echo -icanon raw

        # Send iTerm2-proprietary code. Other terminals ought to ignore it (but are
        # free to use it respectfully).  The response won't start with a 0 so we can
        # distinguish it from the response to DSR 5. It should contain the terminal's
        # name followed by a space followed by its version number and be terminated
        # with an n.
        echo -n '[1337n'

        # Report device status. Responds with esc [ 0 n. All terminals support this. We
        # do this because if the terminal will not respond to iTerm2's custom escape
        # sequence, we can still read from stdin without blocking indefinitely.
        echo -n '[5n'

        set version_string (_read_dsr)
        if [ "$version_string" != "0" -a "$version_string" != "3" ]
            set junk (_read_dsr)           
        else
            set version_string ""
        end

        echo version_string=$version_string

        return 0
    end
end
