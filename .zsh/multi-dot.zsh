# This is a Zsh shell script function named `multi-dot`. It's designed to modify
# the left buffer (`LBUFFER`) of the command line in Zsh.
#
# When you type ".." in the command line, this function checks if the last two
# characters of the left buffer are "..". If they are, it removes the last two
# characters and appends "../." to the end of the buffer.
#
# The `zle self-insert` command is then executed, which inserts the character
# typed by the user into the buffer at the cursor's position.
#
# Finally, `zle -N multi-dot` binds the function `multi-dot` to the Zsh Line
# Editor (ZLE), which is the command line interface for Zsh. This means that the
# function will be called whenever the user types ".." in the command line.
function multi-dot() {
  local dots=$LBUFFER[-2,-1]
  if [[ $dots == ".." ]]; then
    LBUFFER=$LBUFFER[1,-3]'../.'
  fi
  zle self-insert
}
zle -N multi-dot
