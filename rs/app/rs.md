% RS(1)
% Jonathan Cowling
% October 2021

# NAME

rs – a build tool for running bash scripts

# SYNOPSIS

**rs** [**--version|-v**] | [**--help|-h**] | [**--list|-l**] | [**--tree|-t**] [*\<path\>* [*\<to\>* [*\<script\>*]]] [**--**] [*args ...*]

# DESCRIPTION

**rs** is a simple-minded tool which creates indices and
body-searches vast quantities of ServiceNow tickets, which is useful to
find out how someone before you solved one particular problem.

# GENERAL OPTIONS

**-h**, **--help**
:   Display a general message, or the help message for a script given by the supplied arguments.

**-l**, **--list**
:   Lists commands in the base script directory, or in a subdirectory specified by the arguments supplied (skips dotfiles).

**-t**, **--tree**
:   List commands recursively in the base script directory, or in a subdirectory specified by the arguments supplied (skips dotfiles).

**-v**, **--version**
:   Print out the current version

# SCRIPT FILES

A script file must be a bash script containing a *run* function, and optionally *help*, and *description* functions.
If a help.sh script exists in the base of the scripts directory (./scripts by default), then calling running *rs --help* with no additional arguments
calls the run function of that script.

# CONFIGURATION

The default configuration file (*/etc/rs/rsrc*) describes the variables that can be set to change how **rs** operates, these variables can be overridden
using a config file in a users config directory (*~/.config/rs/rsrc*), or in the current working directory (*.rsrc*) or by setting the environment variables on the system. 

# LIBRARY

Scripts have access to a number of functions loaded by the rs library:
- rs_cannonicalize - resolves . and .. and makes path absolute
- rs_error, rs_warn, rs_info, rs_success, rs_debug - prints formatted messages (messages are colored if RS_COLOR=true)
- rs_help - prints a default help message for collections

# EXAMPLES

**rs --list**
: list all scripts in the base scripts directory

**rs --tree**
: list all scripts in the base scripts directory or within any sub directories

**rs --list command**
: list all scripts within \<base_scripts_dir\>/command

**rs command sub_command**
: call run function of \<base_scripts_dir\>/command/sub_command.sh

**rs sub_dir**
: call run function of \<base_scripts_dir\>/command.sh
