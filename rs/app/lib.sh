# make path absolute and remove . and ..
# realpath is similar, but is not available on MacOS by default
rs_cannonicalize() {
  # shortcut if path is pwd
  if [[ "$1" == "." ]] || [[ "$1" == "$(pwd)" ]]; then
    echo "$(pwd)"
    return
  fi

  # make path absolute
  NON_CANNONICAL_PATH="$1"
  if [[ "$NON_CANNONICAL_PATH" != $(pwd)/* ]] ; then
    NON_CANNONICAL_PATH="$(pwd)/$NON_CANNONICAL_PATH"
  fi

  # remove '.' and '..'
  IFS='/' read -ra SEGMENTS <<< "$NON_CANNONICAL_PATH"
  declare -a CANONICAL_SEGMENTS_REVERSED
  SKIP_NEXT=false
  for (( i=${#SEGMENTS[@]}-1 ; i>=0 ; i-- )) ; do
      case "${SEGMENTS[i]}" in
        ..) SKIP_NEXT=true ;;
        .) : ;;
        *)
          if $SKIP_NEXT ; then
            SKIP_NEXT=false
          else
            CANONICAL_SEGMENTS_REVERSED+=("${SEGMENTS[i]}")
          fi
          ;;
      esac
  done
  CANONICAL_PATH=""
  for (( i=${#CANONICAL_SEGMENTS_REVERSED[@]}-1 ; i>=0 ; i-- )) ; do
      CANONICAL_PATH+="/${CANONICAL_SEGMENTS_REVERSED[i]}"
  done

  echo "${CANONICAL_PATH#/}"
}

rs_help() {
  # avoid double space
  POSSIBLE_SPACE="" && [ $# -gt 1 ] && POSSIBLE_SPACE=" "
  echo "Get help for a particular script with \"$0 --help $@$POSSIBLE_SPACE<script>\""
  echo "Use \"$0 --list$POSSIBLE_SPACE$@\" to see a list of available scripts"
}

_rs_log_level() {
  case "$RS_LOG_LEVEL" in
    DEBUG)
      echo "3"
      ;;
    INFO)
      echo "2"
      ;;
    WARN)
      echo "1"
      ;;
    ERROR)
      echo "0"
      ;;
    NONE)
      echo "0"
      ;;
    *)
      echo "999"
      ;;
  esac
}

rs_error() {
  [ "$(_rs_log_level)" -lt 0 ] || echo -e "${RS_STYLE_ERROR}[Error]${RS_STYLE_NORMAL}: ${RS_STYLE_BOLD}$@${RS_STYLE_NORMAL}"
}

rs_warn() {
  [ "$(_rs_log_level)" -lt 1 ] || echo -e "${RS_STYLE_WARNING}[Warn]${RS_STYLE_NORMAL}: $@"
}

rs_info() {
  [ "$(_rs_log_level)" -lt 2 ] || echo -e "${RS_STYLE_INFO}[Info]${RS_STYLE_NORMAL}: $@"
}

rs_success() {
  [ "$(_rs_log_level)" -lt 1 ] || echo -e "${RS_STYLE_SUCCESS}[Success]${RS_STYLE_NORMAL}: $@"
}

rs_debug() {
  [ "$(_rs_log_level)" -lt 3 ] || echo -e "${RS_STYLE_DEBUG}[Debug]${RS_STYLE_NORMAL}: $@"
}

if $RS_COLOR; then
  : "${RS_STYLE_ERROR:=\\033[0;91m}"
  : "${RS_STYLE_WARNING:=\\033[0;93m}"
  : "${RS_STYLE_INFO:=\\033[0;94m}"
  : "${RS_STYLE_SUCCESS:=\\033[0;92m}"
  : "${RS_STYLE_DEBUG:=\\033[0;96m}"
  : "${RS_STYLE_BOLD:=\\033[1m}"
  : "${RS_STYLE_NORMAL:=\\033[0m}"
else
  : "${RS_STYLE_ERROR:=}"
  : "${RS_STYLE_WARNING:=}"
  : "${RS_STYLE_INFO:=}"
  : "${RS_STYLE_SUCCESS:=}"
  : "${RS_STYLE_DEBUG:=}"
  : "${RS_STYLE_BOLD:=}"
  : "${RS_STYLE_NORMAL:=}"
fi

