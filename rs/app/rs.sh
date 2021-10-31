#!/usr/bin/env bash

# set -euo pipefail

: "${RS_RC:=.rsrc}"
: "${RS_LIB:=/usr/lib/rs/lib.sh}"
: "${RS_SCRIPTS_BASE_DIR:=./scripts}"
: "${RS_COLOR:=false}"
: "${RS_LOG_LEVEL:=WARN}"
: "${INDENT_SIZE:=2}"

[ -f "/etc/rs/rsrc" ] && source "/etc/rs/rsrc"
[ -f "${HOME}/.config/rs/rsrc" ] && source "${HOME}/.config/rs/rsrc"
[ -f "${RS_RC}" ] && source "${RS_RC}"
[ -f "${RS_LIB}" ] && source "${RS_LIB}"


# file permissions should stop any actual malace, but let's be good citizens and disallow calling scripts that aren't in $RS_SCRIPTS_BASE_DIR
_rs_check_script_within_project_folder() {
  [[ "$(rs_cannonicalize "$1")" != "$(rs_cannonicalize "${RS_SCRIPTS_BASE_DIR%/}")/*" ]]
}

_rs_in_array() {
  local ITEM
  for ITEM in "${@:2}"; do
    [ "$ITEM" == "$1" ] && return 0
  done
  return 1
}

_rs_help() {
  if [ "$#" -le "1" ]; then
    # look for help script
    if [ ! -f "$RS_SCRIPTS_BASE_DIR/help.sh" ]; then
      rs_warn "No \"$RS_SCRIPTS_BASE_DIR/help.sh\" script found, showing default help message" >&2
      rs_help
      return
    fi

    (
      source "$RS_SCRIPTS_BASE_DIR/help.sh"
      if [ "$(type -t run)" != "function" ]; then
        rs_error "\"$RS_SCRIPTS_BASE_DIR/help.sh\" does not have a run function" >&2
        exit 1
      fi
      
      run
    )
    return $?
  fi

  SCRIPT="$(printf "%s/" "${@:2}")"
  SCRIPT="$RS_SCRIPTS_BASE_DIR/${SCRIPT%/}.sh"

  if ! _rs_check_script_within_project_folder "$SCRIPT"; then
    rs_error "\"$SCRIPT\" is not within $RS_SCRIPTS_BASE_DIR directory" >&2
    return 1
  fi

  if [ ! -f "$SCRIPT" ]; then
    rs_error "There is no script $SCRIPT" >&2
    return 1
  fi

  (
    source "$SCRIPT"
    if [ "$(type -t help)" != "function" ]; then
      rs_error "\"$SCRIPT\" does not have a help function" >&2
      exit 1
    fi
    
    help "${@:2}"
  )
}

_rs_list() {
  # join args into path
  SCRIPTS_DIR="$( rs_cannonicalize "$RS_SCRIPTS_BASE_DIR/$( printf "%s/" "." "${@:2}" )" )"

  if ! _rs_check_script_within_project_folder "$SCRIPTS_DIR"; then
    rs_error "$SCRIPTS_DIR is not within $RS_SCRIPTS_BASE_DIR directory" >&2
    return 1
  fi

  if [ ! -d "$SCRIPTS_DIR" ]; then
    rs_error "There are no scripts in $SCRIPTS_DIR" >&2
    return 1
  fi

  for script in $(find "$SCRIPTS_DIR" -mindepth 1 -maxdepth 1 -not -name '.*'); do
    # get description from script or fallback to default
    if [ -f "$script" ] && [ "${script##*.}" == "sh" ]; then
      DESCRIPTION="$(
        (source "$script" && [ "$(type -t description)" == "function" ] && description "${@:2}" ) || echo "No description provided"
      )"
      SCRIPT_FILE="$(basename "$script")"
      echo "${SCRIPT_FILE%.sh} - $DESCRIPTION"
    fi

    # get default description for collections without similarly named file
    if [ -d "$script" ] && [ ! -f "${script}.sh" ] && [ -n "$(find "$script" -mindepth 1 -maxdepth 1 -not -name '.*' -name '*.sh')" ]; then
      SCRIPT_FILE="$(basename "$script")"
      # avoid double space
      POSSIBLE_SPACE="" && [ $# -gt 1 ] && POSSIBLE_SPACE=" "
      echo "$SCRIPT_FILE - a collection of scripts, use \"$0 --list ${@:2}$POSSIBLE_SPACE$SCRIPT_FILE\" to see available sub scripts"
    fi
  done
}

_rs_tree() {
  ROOT="$( rs_cannonicalize "$RS_SCRIPTS_BASE_DIR/$(printf "%s/" "." "${@:2}")" )"

  if ! _rs_check_script_within_project_folder "$ROOT"; then
    rs_error "$ROOT is not within $RS_SCRIPTS_BASE_DIR directory" >&2
    return 1
  fi

  declare -a PREVIOUS_SCRIPT_COMPONENTS ALREADY_PRINTED
  while read -r SCRIPT; do
    IFS='/' read -ra SCRIPT_COMPONENTS <<< "${SCRIPT#"$ROOT/"}"

    for ((i=0; i<${#SCRIPT_COMPONENTS[@]}-1; i++)); do

      if [ "${PREVIOUS_SCRIPT_COMPONENTS[i]}" == "${SCRIPT_COMPONENTS[i]}" ]; then
        continue
      fi

      POSSIBLE_SCRIPT="$(printf "%s/" "${SCRIPT_COMPONENTS[@]:0:i+1}" )"
      POSSIBLE_SCRIPT="${ROOT}/${POSSIBLE_SCRIPT%/}.sh"

      if _rs_in_array "$POSSIBLE_SCRIPT" "${ALREADY_PRINTED[@]}"; then
        continue
      fi
      
      if [ -f "$POSSIBLE_SCRIPT" ]; then
        DESCRIPTION="$(
          (source $POSSIBLE_SCRIPT && [ "$(type -t description)" == "function" ] && description "${@:2}") || echo "No description provided"
        )"
        SCRIPT_FILE="${SCRIPT_COMPONENTS[i]}"
        printf "%$((i * INDENT_SIZE)).s%s - %s\n" ' ' "${SCRIPT_FILE%.sh}" "$DESCRIPTION"
        ALREADY_PRINTED+=( "$POSSIBLE_SCRIPT" )
        continue
      fi

      printf "%$((i * INDENT_SIZE)).s%s\n" ' ' "${SCRIPT_COMPONENTS[i]}"
    done

    if _rs_in_array "$SCRIPT" "${ALREADY_PRINTED[@]}"; then
      PREVIOUS_SCRIPT_COMPONENTS=("${SCRIPT_COMPONENTS[@]}")
      continue
    fi

    DESCRIPTION="$(
      (source $SCRIPT && [ "$(type -t description)" == "function" ] && description "${@:2}") || echo "No description provided"
    )"
    SCRIPT_FILE="${SCRIPT_COMPONENTS[i]}"
    printf "%$((i * INDENT_SIZE)).s%s - %s\n" ' ' "${SCRIPT_FILE%.sh}" "$DESCRIPTION"

    ALREADY_PRINTED+=( "$SCRIPT" )
    PREVIOUS_SCRIPT_COMPONENTS=("${SCRIPT_COMPONENTS[@]}")

  done < <(find "$ROOT" -mindepth 1 -name '.*' -prune -or -name '*.sh' -type f )
}

if [ $# -eq 0 ]; then
  _rs_help
  echo -e "\ntop level available scripts are:\n"
  _rs_list
  exit 1
fi

if [ "$1" == "--help" ] || [ "$1" == "-h" ] || [ "$1" == "-?" ]; then
  _rs_help "$@"
  exit $?
fi

if [ "$1" == "--list" ] || [ "$1" == "-l" ]; then
  _rs_list "$@"
  exit $?
fi

if [ "$1" == "--tree" ] || [ "$1" == "-t" ]; then
  _rs_tree "$@"
  exit $?
fi

if [ "$1" == "--version" ] || [ "$1" == "-v" ]; then
  rs_version
  exit $?
fi

SCRIPT=""
ARGS_START=1
# loop through args looking for "--" or last possible script
for (( i=1 ; i<$# ; i++ )) ; do
  if [ "${!i}" == "--" ]; then
    SCRIPT="$(printf "%s/" "${@:1:$((i - 1))}")"
    SCRIPT="$RS_SCRIPTS_BASE_DIR/${SCRIPT%/}.sh"
    ARGS_START="$((i+1))"
    break
  fi

  # FIXME: for some reason this doesn't work test with app/rs.sh build set-version -- 0.1.0

  DIR=$(printf "%s/" "${@:1:$i}")
  DIR="$RS_SCRIPTS_BASE_DIR/${DIR}"

  # keep track of the last existing script
  if [ -f "${DIR%/}.sh" ]; then
    SCRIPT="${DIR%/}.sh"
    ARGS_START="$((i+1))"
    break
  fi
done

if [ -z "$SCRIPT" ]; then
  SCRIPT="$(printf "%s/" "${@}")"
  SCRIPT="$RS_SCRIPTS_BASE_DIR/${SCRIPT%/}.sh"
fi

if ! _rs_check_script_within_project_folder "$SCRIPT"; then
  rs_error "$SCRIPT is not within $RS_SCRIPTS_BASE_DIR directory" >&2
  return 1
fi

if [ ! -f "$SCRIPT" ]; then
  rs_error "There is no script $SCRIPT" >&2
  return 1
fi

(
  source "$SCRIPT"
  if [ "$(type -t run)" != "function" ]; then
    rs_error "Script $SCRIPT has no run function" >&2
    exit 1
  fi

  run "${@:ARGS_START}"
)
