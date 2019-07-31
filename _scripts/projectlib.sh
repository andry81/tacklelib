#!/bin/bash

# Script can be ONLY included by "source" command.
if [[ -n "$BASH" && (-z "$BASH_LINENO" || ${BASH_LINENO[0]} -gt 0) ]] && (( ! ${#SOURCE_PROJECTLIB_SH} )); then

SOURCE_PROJECTLIB_SH=1 # including guard

source "/bin/bash_entry" || exit $?
tkl_include "buildlib.sh" || exit $?

function GenerateSrc()
{
  local CONFIG_FILE_IN="$PROJECT_ROOT/_config/_scripts/01/${BASH_SOURCE_FILE_NAME%[.]*}.in"

  local IFS
  while IFS=$'|\t\r\n' read -r FromFilePath ToFilePath; do
    [[ -z "${FromFilePath//[$' \t']/}" ]] && continue
    [[ -z "${ToFilePath//[$' \t']/}" ]] && continue
    [[ "${FromFilePath:i:1}" == "#" ]] && continue

    echo "\"$PROJECT_ROOT/$FromFilePath\" -> \"$PROJECT_ROOT/$ToFilePath\""
    {
      cat "$PROJECT_ROOT/$FromFilePath"
    } > "$PROJECT_ROOT/$ToFilePath"
  done < "$CONFIG_FILE_IN"

  local CONFIG_FILE_IN="$PROJECT_ROOT/_config/_scripts/01/${BASH_SOURCE_FILE_NAME%[.]*}.deps.${BASH_SOURCE_FILE_NAME##*[.]}.in"

  local IFS
  while IFS=$'|\t\r\n' read -r ScriptFilePath ScriptCmdLine; do
    [[ -z "${ScriptFilePath//[$' \t']/}" ]] && continue
    [[ "${ScriptFilePath:i:1}" == "#" ]] && continue
    ScriptCmdLine="${ScriptCmdLine//[$'\r\n']/}" # trim line returns
    declare -a "ScriptCmdLineArr=($ScriptCmdLine)" # evaluate command line only
    Call "$PROJECT_ROOT/$ScriptFilePath" "${ScriptCmdLineArr[@]}" || return $?
  done < "$CONFIG_FILE_IN"

  return 0
}

function GenerateConfig()
{
  local CMDLINE_SYSTEM_FILE_IN="$PROJECT_ROOT/_config/_scripts/02/${BASH_SOURCE_FILE_NAME%[.]*}.system.${BASH_SOURCE_FILE_NAME##*[.]}.in"
  local CMDLINE_USER_FILE_IN="$PROJECT_ROOT/_config/_scripts/02/${BASH_SOURCE_FILE_NAME%[.]*}.user.${BASH_SOURCE_FILE_NAME##*[.]}.in"

  MakeCommandArgumentsFromFile -e "$CMDLINE_SYSTEM_FILE_IN"
  eval "CMAKE_CMD_LINE_SYSTEM=($RETURN_VALUE)"

  MakeCommandArgumentsFromFile -e "$CMDLINE_USER_FILE_IN"
  eval "CMAKE_CMD_LINE_USER=($RETURN_VALUE)"

  Call cmake "${CMAKE_CMD_LINE_SYSTEM[@]}" || return $LastError
  Call cmake "${CMAKE_CMD_LINE_USER[@]}" || return $LastError

  local CONFIG_FILE_IN="$PROJECT_ROOT/_config/_scripts/02/${BASH_SOURCE_FILE_NAME%[.]*}.deps.${BASH_SOURCE_FILE_NAME##*[.]}.in"
  local IFS

  local IFS
  while IFS=$'|\t\r\n' read -r ScriptFilePath ScriptCmdLine; do 
    [[ -z "${ScriptFilePath//[$' \t']/}" ]] && continue
    [[ "${ScriptFilePath:i:1}" == "#" ]] && continue
    ScriptCmdLine="${ScriptCmdLine//[$'\r\n']/}" # trim line returns
    declare -a "ScriptCmdLineArr=($ScriptCmdLine)" # evaluate command line only
    Call "$PROJECT_ROOT/$ScriptFilePath" "${ScriptCmdLineArr[@]}" || return $?
  done < "$CONFIG_FILE_IN"

  return $LastError
}

function UpdateOsName()
{
  case "$OSTYPE" in
    "msys" | "mingw" | "cygwin")
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

    local IFS=$'; \t\r\n'; for i in $CMAKE_CONFIG_ABBR_TYPES; do
      if [[ "$i" == "$CMAKE_BUILD_TYPE" ]]; then
        local config_type_index=0
        local IFS=$'; \t\r\n'; for j in $CMAKE_CONFIG_TYPES; do
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
  UpdateOsName
  UpdateBuildType

  if (( ! GENERATOR_IS_MULTI_CONFIG )); then
    Call CheckBuildType "$CMAKE_BUILD_TYPE" "$CMAKE_CONFIG_TYPES" || Exit
  fi

  source "$PROJECT_ROOT/_scripts/tools/set_vars_from_files.sh" || Exit
  source "$PROJECT_ROOT/_scripts/tools/set_vars_from_locked_file_pair.sh" || Exit

  # load configuration files again unconditionally
  local CMAKE_BUILD_TYPE_ARG="$CMAKE_BUILD_TYPE"
  [[ -z "$CMAKE_BUILD_TYPE_ARG" ]] && CMAKE_BUILD_TYPE_ARG="."
  Call set_vars_from_files \
    "${CONFIG_VARS_SYSTEM_FILE//;/\\;};${CONFIG_VARS_USER_FILE//;/\\;}" "$OS_NAME" . "$CMAKE_BUILD_TYPE_ARG" . ";" \
    --make_vars \
    "CMAKE_CURRENT_PACKAGE_NEST_LVL;CMAKE_CURRENT_PACKAGE_NEST_LVL_PREFIX;CMAKE_CURRENT_PACKAGE_NAME;CMAKE_CURRENT_PACKAGE_SOURCE_DIR;CMAKE_TOP_PACKAGE_NAME;CMAKE_TOP_PACKAGE_SOURCE_DIR" \
    "0;00;$PROJECT_NAME;${PROJECT_ROOT//;/\\;};$PROJECT_NAME;${PROJECT_ROOT//;/\\;}" \
    --ignore_statement_if_no_filter --ignore_late_expansion_statements || Exit

  source "${ScriptDirPath:-.}/__init2__.sh" || Exit

  local CMDLINE_FILE_IN="$PROJECT_ROOT/_config/_scripts/03/$ScriptFileName.in"

  MakeCommandArgumentsFromFile -e "$CMDLINE_FILE_IN"

  local CMAKE_CMD_LINE="$RETURN_VALUE"

  [[ -n "$CMAKE_BUILD_TYPE" ]] && CMAKE_CMD_LINE="$CMAKE_CMD_LINE -D 'CMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE'"
  [[ -n "$CMAKE_GENERATOR_TOOLSET" ]] && CMAKE_CMD_LINE="$CMAKE_CMD_LINE -T '$CMAKE_GENERATOR_TOOLSET'"
  [[ -n "$CMAKE_GENERATOR_PLATFORM" ]] && CMAKE_CMD_LINE="$CMAKE_CMD_LINE -A '$CMAKE_GENERATOR_PLATFORM'"

  eval "CMAKE_CMD_LINE_ARR=($CMAKE_CMD_LINE)"

  Pushd "$CMAKE_BUILD_ROOT" && {
    Call cmake "${CMAKE_CMD_LINE_ARR[@]}" || { Popd; return $LastError; }
    Popd
  }

  return $LastError
}

function Build()
{
  UpdateOsName
  UpdateBuildType

  if (( ! GENERATOR_IS_MULTI_CONFIG )); then
    Call CheckBuildType "$CMAKE_BUILD_TYPE" "$CMAKE_CONFIG_TYPES" || Exit
  fi

  source "$PROJECT_ROOT/_scripts/tools/set_vars_from_files.sh" || Exit
  source "$PROJECT_ROOT/_scripts/tools/set_vars_from_locked_file_pair.sh" || Exit

  # load configuration files again unconditionally
  local CMAKE_BUILD_TYPE_ARG="$CMAKE_BUILD_TYPE"
  [[ -z "$CMAKE_BUILD_TYPE_ARG" ]] && CMAKE_BUILD_TYPE_ARG="."
  Call set_vars_from_files \
    "${CONFIG_VARS_SYSTEM_FILE//;/\\;};${CONFIG_VARS_USER_FILE//;/\\;}" "$OS_NAME" . "$CMAKE_BUILD_TYPE_ARG" . ";" \
    --make_vars \
    "CMAKE_CURRENT_PACKAGE_NEST_LVL;CMAKE_CURRENT_PACKAGE_NEST_LVL_PREFIX;CMAKE_CURRENT_PACKAGE_NAME;CMAKE_CURRENT_PACKAGE_SOURCE_DIR;CMAKE_TOP_PACKAGE_NAME;CMAKE_TOP_PACKAGE_SOURCE_DIR" \
    "0;00;$PROJECT_NAME;${PROJECT_ROOT//;/\\;};$PROJECT_NAME;${PROJECT_ROOT//;/\\;}" \
    --ignore_statement_if_no_filter --ignore_late_expansion_statements || Exit

  source "${ScriptDirPath:-.}/__init2__.sh" || Exit

  local CMDLINE_FILE_IN="$PROJECT_ROOT/_config/_scripts/04/$ScriptFileName.in"

  MakeCommandArgumentsFromFile -e "$CMDLINE_FILE_IN"

  local CMAKE_CMD_LINE="$RETURN_VALUE"

  eval "CMAKE_CMD_LINE_ARR=($CMAKE_CMD_LINE)"

  Pushd "$CMAKE_BUILD_ROOT" && {
    Call cmake "${CMAKE_CMD_LINE_ARR[@]}" || { Popd; return $LastError; }
    Popd
  }

  return $LastError
}

function Install()
{
  UpdateOsName
  UpdateBuildType

  if (( ! GENERATOR_IS_MULTI_CONFIG )); then
    Call CheckBuildType "$CMAKE_BUILD_TYPE" "$CMAKE_CONFIG_TYPES" || Exit
  fi

  source "$PROJECT_ROOT/_scripts/tools/set_vars_from_files.sh" || Exit
  source "$PROJECT_ROOT/_scripts/tools/set_vars_from_locked_file_pair.sh" || Exit

  # load configuration files again unconditionally
  local CMAKE_BUILD_TYPE_ARG="$CMAKE_BUILD_TYPE"
  [[ -z "$CMAKE_BUILD_TYPE_ARG" ]] && CMAKE_BUILD_TYPE_ARG="."
  Call set_vars_from_files \
    "${CONFIG_VARS_SYSTEM_FILE//;/\\;};${CONFIG_VARS_USER_FILE//;/\\;}" "$OS_NAME" . "$CMAKE_BUILD_TYPE_ARG" . ";" \
    --make_vars \
    "CMAKE_CURRENT_PACKAGE_NEST_LVL;CMAKE_CURRENT_PACKAGE_NEST_LVL_PREFIX;CMAKE_CURRENT_PACKAGE_NAME;CMAKE_CURRENT_PACKAGE_SOURCE_DIR;CMAKE_TOP_PACKAGE_NAME;CMAKE_TOP_PACKAGE_SOURCE_DIR" \
    "0;00;$PROJECT_NAME;${PROJECT_ROOT//;/\\;};$PROJECT_NAME;${PROJECT_ROOT//;/\\;}" \
    --ignore_statement_if_no_filter --ignore_late_expansion_statements || Exit

  source "${ScriptDirPath:-.}/__init2__.sh" || Exit

  local CMDLINE_FILE_IN="$PROJECT_ROOT/_config/_scripts/05/$ScriptFileName.in"

  MakeCommandArgumentsFromFile -e "$CMDLINE_FILE_IN"

  eval "CMAKE_CMD_LINE=($RETURN_VALUE)"

  Pushd "$CMAKE_BUILD_ROOT" && {
    Call cmake "${CMAKE_CMD_LINE[@]}" || { Popd; return $LastError; }
    Popd
  }

  return $LastError
}

function PostInstall()
{
  UpdateOsName
  UpdateBuildType

  if (( ! GENERATOR_IS_MULTI_CONFIG )); then
    Call CheckBuildType "$CMAKE_BUILD_TYPE" "$CMAKE_CONFIG_TYPES" || Exit
  fi

  source "$PROJECT_ROOT/_scripts/tools/set_vars_from_files.sh" || Exit
  source "$PROJECT_ROOT/_scripts/tools/set_vars_from_locked_file_pair.sh" || Exit

  # load configuration files again unconditionally
  local CMAKE_BUILD_TYPE_ARG="$CMAKE_BUILD_TYPE"
  [[ -z "$CMAKE_BUILD_TYPE_ARG" ]] && CMAKE_BUILD_TYPE_ARG="."
  Call set_vars_from_files \
    "${CONFIG_VARS_SYSTEM_FILE//;/\\;};${CONFIG_VARS_USER_FILE//;/\\;}" "$OS_NAME" . "$CMAKE_BUILD_TYPE_ARG" . ";" \
    --make_vars \
    "CMAKE_CURRENT_PACKAGE_NEST_LVL;CMAKE_CURRENT_PACKAGE_NEST_LVL_PREFIX;CMAKE_CURRENT_PACKAGE_NAME;CMAKE_CURRENT_PACKAGE_SOURCE_DIR;CMAKE_TOP_PACKAGE_NAME;CMAKE_TOP_PACKAGE_SOURCE_DIR" \
    "0;00;$PROJECT_NAME;${PROJECT_ROOT//;/\\;};$PROJECT_NAME;${PROJECT_ROOT//;/\\;}" \
    --ignore_statement_if_no_filter --ignore_late_expansion_statements || Exit

  source "${ScriptDirPath:-.}/__init2__.sh" || Exit

  #local CMDLINE_FILE_IN="$PROJECT_ROOT/_config/_scripts/05/$ScriptFileName.in"

  Pushd "$CMAKE_INSTALL_ROOT" && {
    PostInstallImpl "$@" || { Popd; return $LastError; }
    Popd
  }

  return $LastError
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

  local IFS
  local dir
  local from_dir
  local i

  # command parameters for the `collect_ldd_deps.sh` scripts
  local file_deps_root_list
  local file_deps_mkdir_list
  local file_deps_cpdir_list
  local IFS=$':\t\r\n'
  declare -a "file_deps_root_list=(\$FILE_DEPS_ROOT_LIST)"
  declare -a "file_deps_mkdir_list=(\$FILE_DEPS_MKDIR_LIST)"
  declare -a "file_deps_cpdir_list=(\$FILE_DEPS_CPDIR_LIST)"

  # create application directories at first
  MakeDir "${file_deps_mkdir_list[@]}" || Exit

  # copy directories recursively
  i=0
  for dir in "${file_deps_cpdir_list[@]}"; do
    (( i == 0 )) && from_dir="$dir"
    if (( (i % 2) == 1 )); then
      Call cp -R "$from_dir" "$dir" || return Exit
    fi
    (( i++ ))
  done

  # collect shared object dependencies
  Call "$PROJECT_ROOT/_scripts/deploy/collect_ldd_deps.sh" "$FILE_DEPS_LIST_TO_FIND" "$FILE_DEPS_ROOT_LIST" \
    "$FILE_DEPS_LIST_TO_EXCLUDE" "$FILE_DEPS_LD_PATH_LIST" deps.lst . || return $?

  # create user symlinks
  Call "$PROJECT_ROOT/_scripts/deploy/create_links.sh" -u . || return $?

  # generate common links file from collected and created dependencies
  Call "$PROJECT_ROOT/_scripts/deploy/gen_links.sh" . _scripts/deploy || return $?

  # patch executables
  Call patchelf --set-interpreter "./lib/ld-linux.so.2" --set-rpath "\$ORIGIN:\$ORIGIN/lib" "./$PROJECT_NAME" || return $?
  Call patchelf --shrink-rpath "./$PROJECT_NAME" || return $?

  local file

  for file in "${file_deps_root_list[@]}"; do
    MoveFile -L "$file" "lib/" || return $?
  done

  # copy approot if exists
  if [[ -d "$PROJECT_ROOT/deploy/approot" ]]; then
    Call cp -R "$PROJECT_ROOT/deploy/approot/." "$PWD" || return $?
  fi

  # copy specific scripts if exists
  if [[ -d "$PROJECT_ROOT/_scripts/deploy" ]]; then
    Call cp -R "$PROJECT_ROOT/_scripts/deploy" "$PWD/_scripts" || return $?
  fi
  if [[ -d "$PROJECT_ROOT/_scripts/admin" ]]; then
    Call cp -R "$PROJECT_ROOT/_scripts/admin" "$PWD/_scripts" || return $?
  fi

  local file_name

  # rename files in the current directory beginning by the `$` character
  local IFS=$' \t\r\n'; for file in `find "$PWD" -type f -name "\\\$*"`; do
    GetFileDir "$file"
    file_dir="$RETURN_VALUE"

    GetFileName "$file"

    file_name_prefix=$(echo "$RETURN_VALUE" | { IFS=$'.\r\n'; read -r prefix suffix; echo "$prefix"; })
    file_name_ext=$(echo "$RETURN_VALUE" | { IFS=$'.\r\n'; read -r prefix suffix; echo "$suffix"; })
    file_name_to_rename="${file_name_prefix//\$\{PROJECT_NAME\}/$PROJECT_NAME}.$file_name_ext"

    Call mv "$file" "$file_dir/$file_name_to_rename" || return $?
  done

  return 0
}

function Pack()
{
  UpdateOsName
  UpdateBuildType

  if (( ! GENERATOR_IS_MULTI_CONFIG )); then
    Call CheckBuildType "$CMAKE_BUILD_TYPE" "$CMAKE_CONFIG_TYPES" || Exit
  fi

  source "$PROJECT_ROOT/_scripts/tools/set_vars_from_files.sh" || Exit
  source "$PROJECT_ROOT/_scripts/tools/set_vars_from_locked_file_pair.sh" || Exit

  # load configuration files again unconditionally
  local CMAKE_BUILD_TYPE_ARG="$CMAKE_BUILD_TYPE"
  [[ -z "$CMAKE_BUILD_TYPE_ARG" ]] && CMAKE_BUILD_TYPE_ARG="."
  Call set_vars_from_files \
    "${CONFIG_VARS_SYSTEM_FILE//;/\\;};${CONFIG_VARS_USER_FILE//;/\\;}" "$OS_NAME" . "$CMAKE_BUILD_TYPE_ARG" . ";" \
    --make_vars \
    "CMAKE_CURRENT_PACKAGE_NEST_LVL;CMAKE_CURRENT_PACKAGE_NEST_LVL_PREFIX;CMAKE_CURRENT_PACKAGE_NAME;CMAKE_CURRENT_PACKAGE_SOURCE_DIR;CMAKE_TOP_PACKAGE_NAME;CMAKE_TOP_PACKAGE_SOURCE_DIR" \
    "0;00;$PROJECT_NAME;${PROJECT_ROOT//;/\\;};$PROJECT_NAME;${PROJECT_ROOT//;/\\;}" \
    --ignore_statement_if_no_filter --ignore_late_expansion_statements || Exit

  source "${ScriptDirPath:-.}/__init2__.sh" || Exit

  if [[ ! -d "$NSIS_INSTALL_ROOT" ]]; then
    echo "$0: error: NSIS_INSTALL_ROOT directory does not exist: \`$NSIS_INSTALL_ROOT\`." >&2
    return 255
  fi

  export PATH="$PATH%:$NSIS_INSTALL_ROOT"

  local CMDLINE_FILE_IN="$PROJECT_ROOT/_config/_scripts/07/$ScriptFileName.in"

  MakeCommandArgumentsFromFile -e "$CMDLINE_FILE_IN"

  local CMAKE_CMD_LINE="$RETURN_VALUE"

  eval "CMAKE_CMD_LINE_ARR=($CMAKE_CMD_LINE)"

  Pushd "$CMAKE_BUILD_ROOT" && {
    Call cmake "${CMAKE_CMD_LINE_ARR[@]}" || { Popd; return $LastError; }
    Popd
  }

  return $LastError
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
        exit 4
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
  local IFS

  local IFS=$'; \t\r\n'; for i in $CMAKE_CONFIG_TYPES; do
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

  if [[ -n "$CMAKE_BUILD_TYPE" ]]; then
    local CMAKE_BUILD_DIR="$CMAKE_BUILD_ROOT/$CMAKE_BUILD_TYPE"
    local CMAKE_BIN_DIR="$CMAKE_BIN_ROOT/$CMAKE_BUILD_TYPE"
    local CMAKE_LIB_DIR="$CMAKE_LIB_ROOT/$CMAKE_BUILD_TYPE"
    local CMAKE_CPACK_DIR="$CMAKE_CPACK_ROOT/$CMAKE_BUILD_TYPE"
  else
    local CMAKE_BUILD_DIR="$CMAKE_BUILD_ROOT"
    local CMAKE_BIN_DIR="$CMAKE_BIN_ROOT"
    local CMAKE_LIB_DIR="$CMAKE_LIB_ROOT"
    local CMAKE_CPACK_DIR="$CMAKE_CPACK_ROOT"
  fi

  tkl_get_native_parent_dir "$CMAKE_OUTPUT_ROOT"
  if [[ -z "$RETURN_VALUE" || ! -d "$RETURN_VALUE" ]]; then
    echo "$0: error: parent directory of the CMAKE_OUTPUT_ROOT does not exist \`$CMAKE_OUTPUT_ROOT\`" >&2
    return 1
  fi

  [[ ! -d "$CMAKE_OUTPUT_ROOT" ]] && { mkdir "$CMAKE_OUTPUT_ROOT" || return $?; }

  if [[ ! -z ${CMAKE_OUTPUT_GENERATOR_DIR+x} ]]; then
    tkl_get_native_parent_dir "$CMAKE_OUTPUT_GENERATOR_DIR"
    if [[ -z "$RETURN_VALUE" || ! -d "$RETURN_VALUE" ]]; then
      echo "$0: error: parent directory of the CMAKE_OUTPUT_GENERATOR_DIR does not exist \`$CMAKE_OUTPUT_GENERATOR_DIR\`" >&2
      return 2
    fi

    [[ ! -d "$CMAKE_OUTPUT_GENERATOR_DIR" ]] && { mkdir "$CMAKE_OUTPUT_GENERATOR_DIR" || return $?; }
  fi

  tkl_get_native_parent_dir "$CMAKE_OUTPUT_DIR"
  if [[ -z "$RETURN_VALUE" || ! -d "$RETURN_VALUE" ]]; then
    echo "$0: error: parent directory of the CMAKE_OUTPUT_DIR does not exist \`$CMAKE_OUTPUT_DIR\`" >&2
    return 3
  fi

  [[ ! -d "$CMAKE_OUTPUT_DIR" ]] && { mkdir "$CMAKE_OUTPUT_DIR" || return $?; }

  [[ ! -d "$CMAKE_BUILD_ROOT" ]] && { mkdir "$CMAKE_BUILD_ROOT" || return $?; }
  [[ ! -d "$CMAKE_BIN_ROOT" ]] && { mkdir "$CMAKE_BIN_ROOT" || return $?; }
  [[ ! -d "$CMAKE_LIB_ROOT" ]] && { mkdir "$CMAKE_LIB_ROOT" || return $?; }
  [[ ! -d "$CMAKE_CPACK_ROOT" ]] && { mkdir "$CMAKE_CPACK_ROOT" || return $?; }

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

  tkl_get_native_parent_dir "$CMAKE_CPACK_DIR"
  if [[ -z "$RETURN_VALUE" || ! -d "$RETURN_VALUE" ]]; then
    echo "$0: error: parent directory of the CMAKE_CPACK_DIR does not exist \`$CMAKE_CPACK_DIR\`" >&2
    return 14
  fi

  tkl_return_local CMAKE_BUILD_DIR "$CMAKE_BUILD_DIR"
  tkl_return_local CMAKE_BIN_DIR "$CMAKE_BIN_DIR"
  tkl_return_local CMAKE_LIB_DIR "$CMAKE_LIB_DIR"
  tkl_return_local CMAKE_CPACK_DIR "$CMAKE_CPACK_DIR"

  [[ ! -d "$CMAKE_BUILD_DIR" ]] && { mkdir "$CMAKE_BUILD_DIR" || return $?; }
  [[ ! -d "$CMAKE_BIN_DIR" ]] && { mkdir "$CMAKE_BIN_DIR" || return $?; }
  [[ ! -d "$CMAKE_LIB_DIR" ]] && { mkdir "$CMAKE_LIB_DIR" || return $?; }
  [[ ! -d "$CMAKE_INSTALL_ROOT" ]] && { mkdir "$CMAKE_INSTALL_ROOT" || return $?; }
  [[ ! -d "$CMAKE_CPACK_DIR" ]] && { mkdir "$CMAKE_CPACK_DIR" || return $?; }

  return 0
}

fi
