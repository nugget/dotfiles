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

function it2check --description "Check if we are in an iTerm2 shell" --argument-names MIN_VERSION
    if not status --is-interactive
        # If we're not in an interactive shell, don't do any magic iTerm stuff
        return 1
    else 
        # Read some bytes from stdin. Pass the number of bytes to read as the
        # first argument.
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

        # Extract the terminal name from DSR 1337
        function _terminal --argument-names i 
            echo -n "$i" | sed -e 's/ .*//'
        end

        # Extract the version number from DSR 1337
        function _version --argument-names i 
            echo -n "$i" | sed -e 's/.* //'
        end

        # Support for the extension first appears in this version of iTerm2:
        if [ "$MIN_VERSION" = "" ]
            set MIN_VERSION 2.9.20160304
        end

        # Save our initial stty settings
        set _stty (stty -g)

        # Enter raw mode and turn off echo so the terminal and I can chat quietly.
        stty -echo -icanon raw

        # Send iTerm2-proprietary code. Other terminals ought to ignore it (but
        # are free to use it respectfully).  The response won't start with
        # a 0 so we can distinguish it from the response to DSR 5. It should
        # contain the terminal's name followed by a space followed by its
        # version number and be terminated with an n.
        echo -n '[1337n'

        # Report device status. Responds with esc [ 0 n. All terminals support
        # this. We do this because if the terminal will not respond to iTerm2's
        # custom escape sequence, we can still read from stdin without blocking
        # indefinitely.
        echo -n '[5n'

        set version_string (_read_dsr)
        if [ "$version_string" != "0" -a "$version_string" != "3" ]
            set -l junk (_read_dsr)           
        else
            set version_string ""
        end

        set -l vers (_version $version_string)
        set -l term (_terminal $version_string)

        # Attempt to restore the stty settings
        stty "$_stty"

        if [ "$term" = "ITERM2" ]
            # The version comparison below doesn't actually work well at all
            # because the the test comparison can't cope with rich semantic
            # versioning.  This is a direct, bug-for-bug port of the bundled
            # bash script.
            if [ "$vers" > "$MIN_VERSION" -o "$vers" = "$MIN_VERSION" ]
                return 0
            end
        end

        return 1
    end
end
