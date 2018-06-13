export LANG=en_US.UTF-8
export XDG_HOME_CONFIG=$HOME/.config

# Define environment specific settings.
case $OSTYPE in
    darwin*)
        # For homebrew.
        export path=(
            /usr/local/bin
            /usr/local/opt/coreutils/libexec/gnubin
            /usr/local/opt/gettext/bin
            /usr/local/opt/libiconv/bin
            /usr/local/opt/llvm/bin
            /usr/local/opt/make/libexec/gnubin
            /usr/local/opt/ncurses/bin
            $path
        )

        for e ('ncurses' 'gettext' 'libiconv' 'llvm') {
            export path=(/usr/local/opt/$e/bin $path);
            export LDFLAGS="-L/usr/local/opt/$e/lib $LDFLAGS";
            export CPPFLAGS="-I/usr/local/opt/$e/include $CPPFLAGS"
        }

        export manpath=(
            /usr/local/opt/coreutils/libexec/gnumang
            /usr/local/opt/make/libexec/gnumang
            /usr/local/share/mang
            $manpath
        )

        export fpath=(/usr/local/share/zsh-completions $fpath)
        source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        ;;
    linux*)
        source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

        case $TERM in
            *rxvt*)
                stty -ixon      # Disable XON/XOFF flow control.
                stty stop undef # Disable terminal lock by <Ctrl-S>.
                ;;
        esac
        ;;
esac

# General paths.
export path=(
    $HOME/.local/bin
    $HOME/.cargo/bin
    $path
)

# Set options.
unsetopt beep
unsetopt listbeep

# Prompts.
autoload -Uz add-zsh-hook vcs_info

add-zsh-hook precmd () {
    prev_status_code=$(printf '%3d' $?)
    vcs_info
}

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr '%F{196}-%f'
zstyle ':vcs_info:git:*' stagedstr '%F{047}+%f'
zstyle ':vcs_info:git:*' formats '%F{146}[<%b>%u%c%F{146}]%f'
zstyle ':vcs_info:git:*' actionformats '[%b|%a]%f'

# PROMPT2="%_"
newline=$'\n'
mode_normal='%B%F{118}[NORMAL]%f%b'
mode_insert='%B%F{039}[INSERT]%f%b'
function zle-keymap-select zle-line-init {
    [ $KEYMAP = 'vicmd' ] && mode=$mode_normal || mode=$mode_insert

    PROMPT="%F{251}[%D{%F %T}]$mode%F{009}[%n@%m]%F{%(?.046.196)}[exit: $prev_status_code]%F{110}[%~]$vcs_info_msg_0_$newline%B%F{203}>%f%b "

    zle reset-prompt
}

zle -N zle-line-init
zle -N zle-keymap-select

# History.
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=$HISTSIZE
setopt appendhistory notify
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_reduce_blanks

# Initializations.
[ $+commands[fasd] ] && eval "$(fasd --init auto)"

# Replace some commands.
if [ $+commands[exa] ]; then
    alias ls='exa --color-scale --time-style=long-iso --header --git'
    alias ll='exa --color-scale --time-style=long-iso --header --git -l'
    alias la='exa --color-scale --time-style=long-iso --header --git -a'
else
    alias ls='ls --color --time-style=+%F\ %R -hF'
    alias ll='ls --color --time-style=+%F\ %R -hFl'
    alias la='ls --color --time-style=+%F\ %R -hFa'
fi

alias -g H='| head'
alias -g L='| less'
alias -g M='| more'
alias -g T='| tail'
alias objdump='objdump -M intel'
alias od='od -tx1 -Ax'
alias xxd='xxd -a'

# Complement
zstyle :compinstall filename "$HOME/.zshrc"
autoload -Uz compinit
compinit

# Define EDITOR variable.
# `bindkey` uses this setting.
if [ $+commands[nvim] ]; then
    export EDITOR=nvim
elif [ $+commands[vim] ]; then
    export EDITOR=vim
else
    export EDITOR=vi
fi

# bindkeys.
autoload -Uz history-search-end edit-command-line
zle -N edit-command-line
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey -v
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^B' backward-char
bindkey -M viins '^D' delete-char-or-list
bindkey -M viins '^E' end-of-line
bindkey -M viins '^F' forward-char
bindkey -M viins '^K' kill-line
bindkey -M viins '^P' history-beginning-search-backward-end
bindkey -M viins '^N' history-beginning-search-forward-end
bindkey -M viins "^R" history-incremental-pattern-search-backward
bindkey -M viins '^X^E' edit-command-line

# Functions
function print_term_colors() {
    for c ({000..255}) {
        echo -n "\e[38;5;${c}m $c";
        [ $(($c%16)) -eq 15 ] && echo
    }
}

# Load a machine local scripts.
# NOTE: the last `true` command makes the exit code successes (0).
[ -s $HOME/.zshrc_local ] && source $HOME/.zshrc_local || true
