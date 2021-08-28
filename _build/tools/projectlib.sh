#!/bin/bash

# Script can be ONLY included by "source" command.
[[ -z "$BASH" || (-n "$BASH_LINENO" && BASH_LINENO[0] -le 0) || (-n "$SOURCE_TACKLELIB_PROJECTLIB_SH" && SOURCE_TACKLELIB_PROJECTLIB_SH -ne 0) ]] && return

SOURCE_TACKLELIB_PROJECTLIB_SH=1 # including guard

# CAUTION:
#   All includes must use local modules from the `_build` subdirectory
#   because this is a standalone directory referenced from external projects.
#

source '/bin/bash_tacklelib' || return $?
tkl_include "$TACKLELIB_BASH_ROOT/buildlib.sh" || tkl_abort_include

function GenerateSrc()
{
  local CONFIG_FILE_IN="$TACKLELIB_PROJECT_INPUT_CONFIG_ROOT/_build/$BASH_SOURCE_FILE_NAME}/gen_file_list.in"

  local IFS=$'|\t\r\n'
  while read -r FromFilePath ToFilePath; do
    [[ -z "${FromFilePath//[$' \t']/}" ]] && continue
    [[ -z "${ToFilePath//[$' \t']/}" ]] && continue
    [[ "${FromFilePath:i:1}" == "#" ]] && continue

    echo "\"$TACKLELIB_PROJECT_ROOT/$FromFilePath\" -> \"$TACKLELIB_PROJECT_ROOT/$ToFilePath\""
    {
      cat "$TACKLELIB_PROJECT_ROOT/$FromFilePath"
    } > "$TACKLELIB_PROJECT_ROOT/$ToFilePath"
  done < "$CONFIG_FILE_IN"

  local CONFIG_FILE_IN="$TACKLELIB_PROJECT_INPUT_CONFIG_ROOT/_build/$BASH_SOURCE_FILE_NAME/cmd_list.${BASH_SOURCE_FILE_NAME##*[.]}.in"

  local IFS=$'|\t\r\n'
  while read -r ScriptFilePath ScriptCmdLine; do
    [[ -z "${ScriptFilePath//[$' \t']/}" ]] && continue
    [[ "${ScriptFilePath:i:1}" == "#" ]] && continue
    ScriptCmdLine="${ScriptCmdLine//[$'\r\n']/}" # trim line returns
    declare -a "ScriptCmdLineArr=($ScriptCmdLine)" # evaluate command line only
    tkl_call "$TACKLELIB_PROJECT_ROOT/$ScriptFilePath" "${ScriptCmdLineArr[@]}" || return $?
  done < "$CONFIG_FILE_IN"

  return 0
}

function GenerateConfig()
{
  local CMDLINE_SYSTEM_FILE_IN="$TACKLELIB_PROJECT_INPUT_CONFIG_ROOT/_build/$BASH_SOURCE_FILE_NAME/config.system.${BASH_SOURCE_FILE_NAME##*[.]}.in"
  local CMDLINE_USER_FILE_IN="$TACKLELIB_PROJECT_INPUT_CONFIG_ROOT/_build/$BASH_SOURCE_FILE_NAME/config.0.${BASH_SOURCE_FILE_NAME##*[.]}.in"

  tkl_load_command_line_from_file -e "$CMDLINE_SYSTEM_FILE_IN"
  eval "CMAKE_CMD_LINE_SYSTEM=($RETURN_VALUE)"

  tkl_load_command_line_from_file -e "$CMDLINE_USER_FILE_IN"
  eval "CMAKE_CMD_LINE_USER=($RETURN_VALUE)"

  tkl_call cmake "${CMAKE_CMD_LINE_SYSTEM[@]}" || return $?
  tkl_call cmake "${CMAKE_CMD_LINE_USER[@]}" || return $?

  local CONFIG_FILE_IN="$TACKLELIB_PROJECT_INPUT_CONFIG_ROOT/_build/$BASH_SOURCE_FILE_NAME/cmd_list.${BASH_SOURCE_FILE_NAME##*[.]}.in"

  local IFS=$'|\t\r\n'
  while read -r ScriptFilePath ScriptCmdLine; do 
    [[ -z "${ScriptFilePath//[$' \t']/}" ]] && continue
    [[ "${ScriptFilePath:i:1}" == "#" ]] && continue
    ScriptCmdLine="${ScriptCmdLine//[$'\r\n']/}" # trim line returns
    declare -a "ScriptCmdLineArr=($ScriptCmdLine)" # evaluate command line only
    tkl_call "$TACKLELIB_PROJECT_ROOT/$ScriptFilePath" "${ScriptCmdLineArr[@]}" || return $?
  done < "$CONFIG_FILE_IN"

  return 0
}

function UpdateOsName()
{
  case "$OSTYPE" in
    msys* | mingw* | cygwin*)
      OS_NAME="WIN"
    ;;
    *)
      OS_NAME="UNIX"
    ;;
  esac
}

function UpdateBuildType()
{
  if [[ -n "$CMAKE_BUILD_TYPE" && -n "$CMAKE_CONFIG_ABBR_TYPES" ]]; then
    # convert abbrivated build type name to complete build type name
    local i
    local j

    local is_found=0
    local config_abbr_type_index=0

    local IFS=$'; \t\r\n'
    for i in $CMAKE_CONFIG_ABBR_TYPES; do
      if [[ "$i" == "$CMAKE_BUILD_TYPE" ]]; then
        local config_type_index=0
        for j in $CMAKE_CONFIG_TYPES; do
          if (( config_abbr_type_index == config_type_index )); then
            # update build type
            CMAKE_BUILD_TYPE="$j"
            is_found=1
            break
          fi
          (( config_type_index++ ))
        done
        (( is_found )) && break
      fi
      (( config_abbr_type_index++ ))
    done
  fi
}

function Configure()
{
  tkl_push_trap "echo" RETURN

  UpdateOsName
  UpdateBuildType

  if (( CMAKE_IS_SINGLE_CONFIG )); then
    tkl_call CheckBuildType "$CMAKE_BUILD_TYPE" "$CMAKE_CONFIG_TYPES" || return $?
  fi

  tkl_include "$TACKLELIB_BASH_ROOT/tools/cmake/set_vars_from_files.sh" || return $?
  tkl_include "$TACKLELIB_BASH_ROOT/tools/cmake/set_vars_from_locked_file_pair.sh" || return $?

  # load configuration files again unconditionally
  local CMAKE_BUILD_TYPE_ARG="$CMAKE_BUILD_TYPE"
  [[ -z "$CMAKE_BUILD_TYPE_ARG" ]] && CMAKE_BUILD_TYPE_ARG="."
  tkl_call set_vars_from_files \
    "${CONFIG_VARS_SYSTEM_FILE//;/\\;};${CONFIG_VARS_USER_FILE//;/\\;}" "$OS_NAME" . "$CMAKE_BUILD_TYPE_ARG" . ";" \
    --make_vars \
    "CMAKE_CURRENT_PACKAGE_NEST_LVL;CMAKE_CURRENT_PACKAGE_NEST_LVL_PREFIX;CMAKE_CURRENT_PACKAGE_NAME;CMAKE_CURRENT_PACKAGE_SOURCE_DIR;CMAKE_TOP_PACKAGE_NAME;CMAKE_TOP_PACKAGE_SOURCE_DIR" \
    "0;00;$PROJECT_NAME;${TACKLELIB_PROJECT_ROOT//;/\\;};$PROJECT_NAME;${TACKLELIB_PROJECT_ROOT//;/\\;}" \
    --ignore_statement_if_no_filter --ignore_late_expansion_statements || return $?

  # check if multiconfig.tag is already created
  if [[ -e "$CMAKE_BUILD_ROOT/singleconfig.tag" ]]; then
    if [[ CMAKE_IS_SINGLE_CONFIG -eq 0 ]]; then
      echo "$0: error: single config cmake cache already has been created, can not continue with multi config: CMAKE_GENERATOR=\`$CMAKE_GENERATOR\` CMAKE_BUILD_TYPE=\`$CMAKE_BUILD_TYPE\`." >&2
      tkl_exit 129
    fi
  fi

  if [[ -e "$CMAKE_BUILD_ROOT/multiconfig.tag" ]]; then
    if [[ CMAKE_IS_SINGLE_CONFIG -ne 0 ]]; then
      echo "$0: error: multi config cmake cache already has been created, can not continue with single config: CMAKE_GENERATOR=\`$CMAKE_GENERATOR\` CMAKE_BUILD_TYPE=\`$CMAKE_BUILD_TYPE\`." >&2
      tkl_exit 130
    fi
  fi

  [[ ! -e "$CMAKE_BUILD_ROOT" ]] && mkdir -p "$CMAKE_BUILD_ROOT"

  if [[ CMAKE_IS_SINGLE_CONFIG -ne 0 ]]; then
    echo '' > "$CMAKE_BUILD_ROOT/singleconfig.tag"
    local CMDLINE_FILE_IN="$TACKLELIB_PROJECT_INPUT_CONFIG_ROOT/_build/$BASH_SOURCE_FILE_NAME/singleconfig/cmdline.in"
  else
    echo '' > "$CMAKE_BUILD_ROOT/multiconfig.tag"
    local CMDLINE_FILE_IN="$TACKLELIB_PROJECT_INPUT_CONFIG_ROOT/_build/$BASH_SOURCE_FILE_NAME/multiconfig/cmdline.in"
  fi

  tkl_include "$TACKLELIB_PROJECT_ROOT/_build/__init__/__init2__.sh" || return $?

  tkl_load_command_line_from_file -e "$CMDLINE_FILE_IN"

  local CMAKE_CMD_LINE="$RETURN_VALUE"

  [[ -n "$CMAKE_BUILD_TYPE" ]] && CMAKE_CMD_LINE="$CMAKE_CMD_LINE -D 'CMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE'"
  [[ -n "$CMAKE_GENERATOR_TOOLSET" ]] && CMAKE_CMD_LINE="$CMAKE_CMD_LINE -T '$CMAKE_GENERATOR_TOOLSET'"
  [[ -n "$CMAKE_GENERATOR_PLATFORM" ]] && CMAKE_CMD_LINE="$CMAKE_CMD_LINE -A '$CMAKE_GENERATOR_PLATFORM'"

  eval "CMAKE_CMD_LINE_ARR=($CMAKE_CMD_LINE)"

  tkl_call tkl_pushd "$CMAKE_BUILD_DIR" && {
    tkl_push_trap 'tkl_popd' RETURN
    tkl_call cmake "${CMAKE_CMD_LINE_ARR[@]}" "$@" || return $?
  } || return 255

  return 0
}

function Build()
{
  UpdateOsName
  UpdateBuildType

  if (( ! GENERATOR_IS_MULTI_CONFIG )); then
    tkl_call CheckBuildType "$CMAKE_BUILD_TYPE" "$CMAKE_CONFIG_TYPES" || return $?
  fi

  tkl_include "$TACKLELIB_BASH_ROOT/tools/cmake/set_vars_from_files.sh" || return $?
  tkl_include "$TACKLELIB_BASH_ROOT/tools/cmake/set_vars_from_locked_file_pair.sh" || return $?

  # load configuration files again unconditionally
  local CMAKE_BUILD_TYPE_ARG="$CMAKE_BUILD_TYPE"
  [[ -z "$CMAKE_BUILD_TYPE_ARG" ]] && CMAKE_BUILD_TYPE_ARG="."
  tkl_call set_vars_from_files \
    "${CONFIG_VARS_SYSTEM_FILE//;/\\;};${CONFIG_VARS_USER_FILE//;/\\;}" "$OS_NAME" . "$CMAKE_BUILD_TYPE_ARG" . ";" \
    --make_vars \
    "CMAKE_CURRENT_PACKAGE_NEST_LVL;CMAKE_CURRENT_PACKAGE_NEST_LVL_PREFIX;CMAKE_CURRENT_PACKAGE_NAME;CMAKE_CURRENT_PACKAGE_SOURCE_DIR;CMAKE_TOP_PACKAGE_NAME;CMAKE_TOP_PACKAGE_SOURCE_DIR" \
    "0;00;$PROJECT_NAME;${TACKLELIB_PROJECT_ROOT//;/\\;};$PROJECT_NAME;${TACKLELIB_PROJECT_ROOT//;/\\;}" \
    --ignore_statement_if_no_filter --ignore_late_expansion_statements || return $?

  tkl_include "$TACKLELIB_PROJECT_ROOT/_build/__init__/__init2__.sh" || return $?

  local CMDLINE_FILE_IN="$TACKLELIB_PROJECT_INPUT_CONFIG_ROOT/_build/$BASH_SOURCE_FILE_NAME/cmdline.in"

  tkl_load_command_line_from_file -e "$CMDLINE_FILE_IN"

  local CMAKE_CMD_LINE="$RETURN_VALUE"

  eval "CMAKE_CMD_LINE_ARR=($CMAKE_CMD_LINE)"

  tkl_call tkl_pushd "$CMAKE_BUILD_DIR" && {
    tkl_push_trap 'tkl_popd' RETURN
    tkl_call cmake "${CMAKE_CMD_LINE_ARR[@]}" "$@" || return $?
  } || return 255

  return 0
}

function Install()
{
  UpdateOsName
  UpdateBuildType

  if (( ! GENERATOR_IS_MULTI_CONFIG )); then
    tkl_call CheckBuildType "$CMAKE_BUILD_TYPE" "$CMAKE_CONFIG_TYPES" || return $?
  fi

  tkl_include "$TACKLELIB_BASH_ROOT/tools/cmake/set_vars_from_files.sh" || return $?
  tkl_include "$TACKLELIB_BASH_ROOT/tools/cmake/set_vars_from_locked_file_pair.sh" || return $?

  # load configuration files again unconditionally
  local CMAKE_BUILD_TYPE_ARG="$CMAKE_BUILD_TYPE"
  [[ -z "$CMAKE_BUILD_TYPE_ARG" ]] && CMAKE_BUILD_TYPE_ARG="."
  tkl_call set_vars_from_files \
    "${CONFIG_VARS_SYSTEM_FILE//;/\\;};${CONFIG_VARS_USER_FILE//;/\\;}" "$OS_NAME" . "$CMAKE_BUILD_TYPE_ARG" . ";" \
    --make_vars \
    "CMAKE_CURRENT_PACKAGE_NEST_LVL;CMAKE_CURRENT_PACKAGE_NEST_LVL_PREFIX;CMAKE_CURRENT_PACKAGE_NAME;CMAKE_CURRENT_PACKAGE_SOURCE_DIR;CMAKE_TOP_PACKAGE_NAME;CMAKE_TOP_PACKAGE_SOURCE_DIR" \
    "0;00;$PROJECT_NAME;${TACKLELIB_PROJECT_ROOT//;/\\;};$PROJECT_NAME;${TACKLELIB_PROJECT_ROOT//;/\\;}" \
    --ignore_statement_if_no_filter --ignore_late_expansion_statements || return $?

  tkl_include "$TACKLELIB_PROJECT_ROOT/_build/__init__/__init2__.sh" || return $?

  local CMDLINE_FILE_IN="$TACKLELIB_PROJECT_INPUT_CONFIG_ROOT/_build/$BASH_SOURCE_FILE_NAME/cmdline.in"

  tkl_load_command_line_from_file -e "$CMDLINE_FILE_IN"

  eval "CMAKE_CMD_LINE=($RETURN_VALUE)"

  tkl_call tkl_pushd "$CMAKE_BUILD_DIR" && {
    tkl_push_trap 'tkl_popd' RETURN
    tkl_call cmake "${CMAKE_CMD_LINE[@]}" "$@" || return $?
  } || return 255

  return 0
}

function PostInstall()
{
  UpdateOsName
  UpdateBuildType

  if (( ! GENERATOR_IS_MULTI_CONFIG )); then
    tkl_call CheckBuildType "$CMAKE_BUILD_TYPE" "$CMAKE_CONFIG_TYPES" || return $?
  fi

  tkl_include "$TACKLELIB_BASH_ROOT/tools/cmake/set_vars_from_files.sh" || return $?
  tkl_include "$TACKLELIB_BASH_ROOT/tools/cmake/set_vars_from_locked_file_pair.sh" || return $?

  # load configuration files again unconditionally
  local CMAKE_BUILD_TYPE_ARG="$CMAKE_BUILD_TYPE"
  [[ -z "$CMAKE_BUILD_TYPE_ARG" ]] && CMAKE_BUILD_TYPE_ARG="."
  tkl_call set_vars_from_files \
    "${CONFIG_VARS_SYSTEM_FILE//;/\\;};${CONFIG_VARS_USER_FILE//;/\\;}" "$OS_NAME" . "$CMAKE_BUILD_TYPE_ARG" . ";" \
    --make_vars \
    "CMAKE_CURRENT_PACKAGE_NEST_LVL;CMAKE_CURRENT_PACKAGE_NEST_LVL_PREFIX;CMAKE_CURRENT_PACKAGE_NAME;CMAKE_CURRENT_PACKAGE_SOURCE_DIR;CMAKE_TOP_PACKAGE_NAME;CMAKE_TOP_PACKAGE_SOURCE_DIR" \
    "0;00;$PROJECT_NAME;${TACKLELIB_PROJECT_ROOT//;/\\;};$PROJECT_NAME;${TACKLELIB_PROJECT_ROOT//;/\\;}" \
    --ignore_statement_if_no_filter --ignore_late_expansion_statements || return $?

  tkl_include "$TACKLELIB_PROJECT_ROOT/_build/__init__/__init2__.sh" || return $?

  #local CMDLINE_FILE_IN="$TACKLELIB_PROJECT_INPUT_CONFIG_ROOT/_build/$BASH_SOURCE_FILE_NAME/cmdline.in"

  tkl_call tkl_pushd "$CMAKE_INSTALL_ROOT" && {
    tkl_push_trap 'tkl_popd' RETURN
    PostInstallImpl "$@" || return $?
  } || return 255

  return 0
}

function PostInstallImpl()
{
  # check global variables existence
  if [[ -z "$FILE_DEPS_ROOT_LIST" ]]; then
    echo "PostInstallImpl: error: FILE_DEPS_ROOT_LIST variable is not set." >&2
    return 254
  fi

  if [[ -z "$FILE_DEPS_LIST_TO_FIND" ]]; then
    echo "PostInstallImpl: error: FILE_DEPS_LIST_TO_FIND variable is not set." >&2
    return 253
  fi

  local dir
  local from_dir

  # command parameters for the `collect_ldd_deps.sh` scripts
  local file_deps_root_list
  local file_deps_mkdir_list
  local file_deps_cpdir_list

  declare -a "file_deps_root_list=(\$FILE_DEPS_ROOT_LIST)"
  declare -a "file_deps_mkdir_list=(\$FILE_DEPS_MKDIR_LIST)"
  declare -a "file_deps_cpdir_list=(\$FILE_DEPS_CPDIR_LIST)"

  # create application directories at first
  tkl_make_dir "${file_deps_mkdir_list[@]}" || return $?

  local IFS=$':\t\r\n'

  # copy directories recursively
  local i=0
  for dir in "${file_deps_cpdir_list[@]}"; do
    (( i == 0 )) && from_dir="$dir"
    if (( (i % 2) == 1 )); then
      tkl_call cp -R "$from_dir" "$dir" || return $?
    fi
    (( i++ ))
  done

  # collect shared object dependencies
  tkl_call "$TACKLELIB_PROJECT_ROOT/_build/deploy/collect_ldd_deps.sh" "$FILE_DEPS_LIST_TO_FIND" "$FILE_DEPS_ROOT_LIST" \
    "$FILE_DEPS_LIST_TO_EXCLUDE" "$FILE_DEPS_LD_PATH_LIST" deps.lst . || return $?

  # create user symlinks
  tkl_call "$TACKLELIB_PROJECT_ROOT/_build/deploy/create_links.sh" -u . || return $?

  # generate common links file from collected and created dependencies
  tkl_call "$TACKLELIB_PROJECT_ROOT/_build/deploy/gen_links.sh" . _build/deploy || return $?

  # patch executables
  tkl_call patchelf --set-interpreter "./lib/ld-linux.so.2" --set-rpath "\$ORIGIN:\$ORIGIN/lib" "./$PROJECT_NAME" || return $?
  tkl_call patchelf --shrink-rpath "./$PROJECT_NAME" || return $?

  local file

  for file in "${file_deps_root_list[@]}"; do
    tkl_move_file -L "$file" "lib/" || return $?
  done

  # copy approot if exists
  if [[ -d "$TACKLELIB_PROJECT_ROOT/deploy/approot" ]]; then
    tkl_call cp -R "$TACKLELIB_PROJECT_ROOT/deploy/approot/." "$PWD" || return $?
  fi

  # copy specific scripts if exists
  if [[ -d "$TACKLELIB_PROJECT_ROOT/_build/deploy" ]]; then
    tkl_call cp -R "$TACKLELIB_PROJECT_ROOT/_build/deploy" "$PWD/_build" || return $?
  fi
  if [[ -d "$TACKLELIB_PROJECT_ROOT/_build/admin" ]]; then
    tkl_call cp -R "$TACKLELIB_PROJECT_ROOT/_build/admin" "$PWD/_build" || return $?
  fi

  local file_name

  # rename files in the current directory beginning by the `$` character
  local IFS=$' \t\r\n'
  for file in `find "$PWD" -type f -name "\\\$*"`; do
    tkl_get_file_dir "$file"
    file_dir="$RETURN_VALUE"

    tkl_get_file_name "$file"

    file_name_prefix=$(echo "$RETURN_VALUE" | { IFS=$'.\r\n'; read -r prefix suffix; echo "$prefix"; })
    file_name_ext=$(echo "$RETURN_VALUE" | { IFS=$'.\r\n'; read -r prefix suffix; echo "$suffix"; })
    file_name_to_rename="${file_name_prefix//\$\{PROJECT_NAME\}/$PROJECT_NAME}.$file_name_ext"

    tkl_call mv "$file" "$file_dir/$file_name_to_rename" || return $?
  done

  return 0
}

function Pack()
{
  UpdateOsName
  UpdateBuildType

  if (( ! GENERATOR_IS_MULTI_CONFIG )); then
    tkl_call CheckBuildType "$CMAKE_BUILD_TYPE" "$CMAKE_CONFIG_TYPES" || return $?
  fi

  tkl_include "$TACKLELIB_BASH_ROOT/tools/cmake/set_vars_from_files.sh" || return $?
  tkl_include "$TACKLELIB_BASH_ROOT/tools/cmake/set_vars_from_locked_file_pair.sh" || return $?

  # load configuration files again unconditionally
  local CMAKE_BUILD_TYPE_ARG="$CMAKE_BUILD_TYPE"
  [[ -z "$CMAKE_BUILD_TYPE_ARG" ]] && CMAKE_BUILD_TYPE_ARG="."
  tkl_call set_vars_from_files \
    "${CONFIG_VARS_SYSTEM_FILE//;/\\;};${CONFIG_VARS_USER_FILE//;/\\;}" "$OS_NAME" . "$CMAKE_BUILD_TYPE_ARG" . ";" \
    --make_vars \
    "CMAKE_CURRENT_PACKAGE_NEST_LVL;CMAKE_CURRENT_PACKAGE_NEST_LVL_PREFIX;CMAKE_CURRENT_PACKAGE_NAME;CMAKE_CURRENT_PACKAGE_SOURCE_DIR;CMAKE_TOP_PACKAGE_NAME;CMAKE_TOP_PACKAGE_SOURCE_DIR" \
    "0;00;$PROJECT_NAME;${TACKLELIB_PROJECT_ROOT//;/\\;};$PROJECT_NAME;${TACKLELIB_PROJECT_ROOT//;/\\;}" \
    --ignore_statement_if_no_filter --ignore_late_expansion_statements || return $?

  tkl_include "$TACKLELIB_PROJECT_ROOT/_build/__init__/__init2__.sh" || return $?

  if [[ ! -d "$NSIS_INSTALL_ROOT" ]]; then
    echo "$0: error: NSIS_INSTALL_ROOT directory does not exist: \`$NSIS_INSTALL_ROOT\`." >&2
    return 255
  fi

  export PATH="$PATH%:$NSIS_INSTALL_ROOT"

  local CMDLINE_FILE_IN="$TACKLELIB_PROJECT_INPUT_CONFIG_ROOT/_build/$BASH_SOURCE_FILE_NAME/cmdline.in"

  tkl_load_command_line_from_file -e "$CMDLINE_FILE_IN"

  local CMAKE_CMD_LINE="$RETURN_VALUE"

  eval "CMAKE_CMD_LINE_ARR=($CMAKE_CMD_LINE)"

  tkl_call tkl_pushd "$CMAKE_BUILD_DIR" && {
    tkl_push_trap 'tkl_popd' RETURN
    tkl_call cmake "${CMAKE_CMD_LINE_ARR[@]}" || return $?
  } || return 255

  return 0
}

function CheckConfigVersion()
{
  local OPTIONAL_COMPARE="${1:-0}"
  local VARS_SYSTEM_FILE_IN="$2"
  local VARS_SYSTEM_FILE="$3"
  local VARS_USER_FILE_IN="$4"
  local VARS_USER_FILE="$5"

  if [[ ! -f "$VARS_SYSTEM_FILE_IN" ]]; then
    echo "$0: error: VARS_SYSTEM_FILE_IN does not exist: \`$VARS_SYSTEM_FILE_IN\`" >&2
    return 1
  fi
  if (( ! OPTIONAL_COMPARE )) && [[ ! -f "$VARS_SYSTEM_FILE" ]]; then
    echo "$0: error: VARS_SYSTEM_FILE does not exist: \`$VARS_SYSTEM_FILE\`" >&2
    return 2
  fi
  if [[ ! -f "$VARS_USER_FILE_IN" ]]; then
    echo "$0: error: VARS_USER_FILE_IN does not exist: \`$VARS_USER_FILE_IN\`" >&2
    return 3
  fi
  if (( ! OPTIONAL_COMPARE )) && [[ ! -f "$VARS_USER_FILE" ]]; then
    echo "$0: error: VARS_USER_FILE does not exist: \`$VARS_USER_FILE\`" >&2
    return 4
  fi

  if [[ -f "$VARS_SYSTEM_FILE" ]]; then
    # Test input and output files on version equality, otherwise we must stop and warn the user to merge the changes by yourself!
    local IFS=$' \t\r\n'
    read -r VARS_FILE_IN_VER_LINE < "$VARS_SYSTEM_FILE_IN"
    read -r VARS_FILE_VER_LINE < "$VARS_SYSTEM_FILE"

    if [[ "${VARS_FILE_IN_VER_LINE:0:12}" == "#%%%% version:" ]]; then
      if [[ "${VARS_FILE_IN_VER_LINE:13}" == "${VARS_FILE_VER_LINE:13}" ]]; then
        echo "$0: error: version of \`$VARS_SYSTEM_FILE_IN\` is not equal to version of \`$VARS_SYSTEM_FILE\`, user must merge changes by yourself!" >&2
        return 3
      fi
    fi
  fi

  if [[ -f "$VARS_USER_FILE" ]]; then
    # Test input and output files on version equality, otherwise we must stop and warn the user to merge the changes by yourself!
    local IFS=$' \t\r\n'
    read -r CMAKE_FILE_IN_VER_LINE < "$VARS_USER_FILE_IN"
    read -r CMAKE_FILE_VER_LINE < "$VARS_USER_FILE"

    if [[ "${CMAKE_FILE_IN_VER_LINE:0:12}" == "#%%%% version:" ]]; then
      if [[ "${CMAKE_FILE_IN_VER_LINE:13}" == "${CMAKE_FILE_VER_LINE:13}" ]]; then
        echo "$0: error: version of \`$VARS_USER_FILE_IN\` is not equal to version of \`$VARS_USER_FILE\`, user must merge changes by yourself!" >&2
        return 4
      fi
    fi
  fi

  return 0
}

function CheckBuildType()
{
  local CMAKE_BUILD_TYPE="$1"
  local CMAKE_CONFIG_TYPES="$2"

  if [[ -z "$CMAKE_BUILD_TYPE" ]]; then
    echo "$0: error: CMAKE_BUILD_TYPE is not defined" >&2
    return 1
  fi
  if [[ -z "$CMAKE_CONFIG_TYPES" ]]; then
    echo "$0: error: CMAKE_CONFIG_TYPES is not defined" >&2
    return 2
  fi

  local is_found=0
  local IFS=$'; \t\r\n'

  for i in $CMAKE_CONFIG_TYPES; do
    if [[ "$i" == "$CMAKE_BUILD_TYPE" ]]; then
      is_found=1
      break
    fi
  done

  if (( ! is_found )); then
    echo "$0: error: CMAKE_BUILD_TYPE is not declared in CMAKE_CONFIG_TYPES: CMAKE_BUILD_TYPE=\`$CMAKE_BUILD_TYPE\` CMAKE_CONFIG_TYPES=\`$CMAKE_CONFIG_TYPES\`" >&2
    return 3
  fi

  return 0
}

function MakeOutputDirectories()
{
  local CMAKE_BUILD_TYPE="$1"
  local GENERATOR_IS_MULTI_CONFIG="$2"

  if [[ -e "$CMAKE_BUILD_ROOT/singleconfig.tag" ]]; then
    if [[ -z "$CMAKE_BUILD_TYPE" ]]; then
      echo "$0: error: CMAKE_BUILD_TYPE must be set for single config cmake cache." >&2
      return 1
    fi
    local CMAKE_BUILD_DIR="$CMAKE_BUILD_ROOT/$CMAKE_BUILD_TYPE"
    local CMAKE_BIN_DIR="$CMAKE_BIN_ROOT/$CMAKE_BUILD_TYPE"
    local CMAKE_LIB_DIR="$CMAKE_LIB_ROOT/$CMAKE_BUILD_TYPE"
    local CMAKE_PACK_DIR="$CMAKE_PACK_ROOT/$CMAKE_BUILD_TYPE"
  elif [[ -e "$CMAKE_BUILD_ROOT/multiconfig.tag" ]]; then
    if [[ GENERATOR_IS_MULTI_CONFIG -eq 0 ]]; then
      echo "$0: error: GENERATOR_IS_MULTI_CONFIG must be already set for multi config cmake cache." >&2
      return 2
    fi
    local CMAKE_BUILD_DIR="$CMAKE_BUILD_ROOT"
    local CMAKE_BIN_DIR="$CMAKE_BIN_ROOT"
    local CMAKE_LIB_DIR="$CMAKE_LIB_ROOT"
    local CMAKE_PACK_DIR="$CMAKE_PACK_ROOT"
  else
    echo "$0: error: cmake cache is not created as single config nor multi config." >&2
    return 3
  fi

  tkl_get_native_parent_dir "$CMAKE_OUTPUT_ROOT"
  if [[ -z "$RETURN_VALUE" || ! -d "$RETURN_VALUE" ]]; then
    echo "$0: error: parent directory of the CMAKE_OUTPUT_ROOT does not exist \`$CMAKE_OUTPUT_ROOT\`" >&2
    return 4
  fi

  [[ ! -d "$CMAKE_OUTPUT_ROOT" ]] && { mkdir "$CMAKE_OUTPUT_ROOT" || return $?; }

  if [[ ! -z ${CMAKE_OUTPUT_GENERATOR_DIR+x} ]]; then
    tkl_get_native_parent_dir "$CMAKE_OUTPUT_GENERATOR_DIR"
    if [[ -z "$RETURN_VALUE" || ! -d "$RETURN_VALUE" ]]; then
      echo "$0: error: parent directory of the CMAKE_OUTPUT_GENERATOR_DIR does not exist \`$CMAKE_OUTPUT_GENERATOR_DIR\`" >&2
      return 5
    fi

    [[ ! -d "$CMAKE_OUTPUT_GENERATOR_DIR" ]] && { mkdir "$CMAKE_OUTPUT_GENERATOR_DIR" || return $?; }
  fi

  tkl_get_native_parent_dir "$CMAKE_OUTPUT_DIR"
  if [[ -z "$RETURN_VALUE" || ! -d "$RETURN_VALUE" ]]; then
    echo "$0: error: parent directory of the CMAKE_OUTPUT_DIR does not exist \`$CMAKE_OUTPUT_DIR\`" >&2
    return 6
  fi

  [[ ! -d "$CMAKE_OUTPUT_DIR" ]] && { mkdir "$CMAKE_OUTPUT_DIR" || return $?; }

  [[ ! -d "$CMAKE_BUILD_ROOT" ]] && { mkdir "$CMAKE_BUILD_ROOT" || return $?; }
  [[ ! -d "$CMAKE_BIN_ROOT" ]] && { mkdir "$CMAKE_BIN_ROOT" || return $?; }
  [[ ! -d "$CMAKE_LIB_ROOT" ]] && { mkdir "$CMAKE_LIB_ROOT" || return $?; }
  [[ ! -d "$CMAKE_PACK_ROOT" ]] && { mkdir "$CMAKE_PACK_ROOT" || return $?; }

  tkl_get_native_parent_dir "$CMAKE_BUILD_DIR"
  if [[ -z "$RETURN_VALUE" || ! -d "$RETURN_VALUE" ]]; then
    echo "$0: error: parent directory of the CMAKE_BUILD_DIR does not exist \`$CMAKE_BUILD_DIR\`" >&2
    return 10
  fi

  tkl_get_native_parent_dir "$CMAKE_BIN_DIR"
  if [[ -z "$RETURN_VALUE" || ! -d "$RETURN_VALUE" ]]; then
    echo "$0: error: parent directory of the CMAKE_BIN_DIR does not exist \`$CMAKE_BIN_DIR\`" >&2
    return 11
  fi

  tkl_get_native_parent_dir "$CMAKE_LIB_DIR"
  if [[ -z "$RETURN_VALUE" || ! -d "$RETURN_VALUE" ]]; then
    echo "$0: error: parent directory of the CMAKE_LIB_DIR does not exist \`$CMAKE_LIB_DIR\`" >&2
    return 12
  fi

  tkl_get_native_parent_dir "$CMAKE_INSTALL_ROOT"
  if [[ -z "$RETURN_VALUE" || ! -d "$RETURN_VALUE" ]]; then
    echo "$0: error: parent directory of the CMAKE_INSTALL_ROOT does not exist \`$CMAKE_INSTALL_ROOT\`" >&2
    return 13
  fi

  tkl_get_native_parent_dir "$CMAKE_PACK_DIR"
  if [[ -z "$RETURN_VALUE" || ! -d "$RETURN_VALUE" ]]; then
    echo "$0: error: parent directory of the CMAKE_PACK_DIR does not exist \`$CMAKE_PACK_DIR\`" >&2
    return 14
  fi

  tkl_return_local CMAKE_BUILD_DIR "$CMAKE_BUILD_DIR"
  tkl_return_local CMAKE_BIN_DIR "$CMAKE_BIN_DIR"
  tkl_return_local CMAKE_LIB_DIR "$CMAKE_LIB_DIR"
  tkl_return_local CMAKE_PACK_DIR "$CMAKE_PACK_DIR"

  [[ ! -d "$CMAKE_BUILD_DIR" ]] && { mkdir "$CMAKE_BUILD_DIR" || return $?; }
  [[ ! -d "$CMAKE_BIN_DIR" ]] && { mkdir "$CMAKE_BIN_DIR" || return $?; }
  [[ ! -d "$CMAKE_LIB_DIR" ]] && { mkdir "$CMAKE_LIB_DIR" || return $?; }
  [[ ! -d "$CMAKE_INSTALL_ROOT" ]] && { mkdir "$CMAKE_INSTALL_ROOT" || return $?; }
  [[ ! -d "$CMAKE_PACK_DIR" ]] && { mkdir "$CMAKE_PACK_DIR" || return $?; }

  return 0
}
