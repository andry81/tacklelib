#!/bin/bash

# Description:
#   Script to initialize a git repository and all common properties.

# Usage:
#   git_init.sh <repo_owner> <repo> [remote:<name0>:<var0>=<value0> [remote:<name1>:<var1>=<value1> [... remote:<nameN>:<varN>=<valueN>]]
#
#   <repo_owner>:
#     Common repository owner for all remotes from `GIT_REPO_DEFAULT_REMOTES`.
#   <repo>:
#     Common repository name for all remotes from `GIT_REPO_DEFAULT_REMOTES`.
#
#   <name>:
#     Repository remote name from `GIT_REPO_DEFAULT_REMOTES`.
#
#     <var>:
#       Variable to use for a remote from `GIT_REPO_DEFAULT_REMOTES`.
#
#     <value>:
#       Value to use for a remote from `GIT_REPO_DEFAULT_REMOTES`.

# Examples:
#   >
#   git_init.sh userA repoA remote:sf:SSH_GIT_AUTH_USER=userB remote:gl:REPO=repoC

# Environment variables (does evaluate as is):
#
#   GIT_REPO_DEFAULT_REMOTES=(
#     gh https://github.com/{{REPO_OWNER}}/{{REPO}}
#     gl https://gitlab.com/{{REPO_OWNER}}/{{REPO}}.git
#     sf ssh://{{SSH_GIT_AUTH_USER}}@git.code.sf.net/p/{{REPO_OWNER}}/{{REPO}}
#   )
#
# If not defined, then these variables automatically sets from the environment:
#
#   SSH_GIT_AUTH_USER
#

# Description:

# Script both for execution and inclusion.
if [[ -n "$BASH" ]]; then

function call()
{
  local IFS=$' \t'
  echo ">$*"
  "$@"
}

function get_remote_url()
{
  local var="$1"
  local name="$2"

  RETURN_VALUE=''

  local remote
  local remote_url
  local num_args
  local i

  eval declare num_args=\${#$var[@]}

  for (( i=0; i < num_args; i+=2 )); do
    eval declare remote=\"\${$var[i]}\"
    eval declare remote_url=\"\${$var[i+1]}\"
    if [[ -n "$remote" && "$remote" == "$name" && -n "$remote_url" ]]; then
      RETURN_VALUE="$remote_url"
      return 0
    fi
  done

  return 255
}

function get_default_remote_url()
{
  get_remote_url GIT_REPO_DEFAULT_REMOTES "$@"
}

function set_remote_url()
{
  local var="$1"
  local name="$2"
  local remote_url="$3"

  local remote
  local num_args
  local i

  eval declare num_args=\${#$var[@]}

  for (( i=0; i < num_args; i+=2 )); do
    eval declare remote=\"\${$var[i]}\"
    if [[ -n "$remote" && "$remote" == "$name" ]]; then
      eval $var[i+1]=\"\$remote_url\"
      return 0
    fi
  done

  return 255
}

function git_init()
{
  local repo_owner="$1"
  local repo="$2"

  if [[ -z "$repo_owner" ]]; then
    echo "$0: error: not defined repo owner" >&2
    return 255
  fi

  if [[ -z "$repo" ]]; then
    echo "$0: error: not defined repo" >&2
    return 255
  fi

  shift 2

  local arg
  local args=("$@")
  local name
  local var
  local value
  local num_args=${#args[@]}
  local i

  local remote_url

  # evaluate and copy environment variables

  eval declare GIT_REPO_DEFAULT_REMOTES=$GIT_REPO_DEFAULT_REMOTES

  local num_remotes=${#GIT_REPO_DEFAULT_REMOTES[@]}
  local remote_urls_arr=()

  for (( i=0; i < num_remotes; i++ )); do
    remote_urls_arr[i]="${GIT_REPO_DEFAULT_REMOTES[i]}"
  done

  # setup from variable parameters
  for (( i=0; i < num_args; i++ )); do
    arg="${args[i]}"

    case "$arg" in
      remote:*)
        value="${arg#*:}"
        name="${value%%:*}"
        value="${value#*:}"
        var="${value%%=*}"
        value="${value#*=}"

        if [[ -z "$name" || -z "$var" || -z "$value" ]]; then
          echo "$0: error: invalid `remote` argument: \`$arg\`" >&2
          return 255
        fi

        if get_remote_url remote_urls_arr "$name"; then
          remote_url="$RETURN_VALUE"

          eval declare remote_url=\"\${remote_url//\\{\\{${var}\\}\\}/\$value}\"

          if ! set_remote_url remote_urls_arr "$name" "$remote_url"; then
            echo "$0: error: invalid remote url setup: $name=\`$arg\`" >&2
            return 255
          fi
        else
          echo "warning: remote name is not found: \`$name\`" >&2
        fi
        ;;
      *)
        echo "$0: error: invalid argument: \`$arg\`" >&2
        return 255
        ;;
    esac

    shift

    arg="$1"
  done

  # setup positional arguments and environment variables at last
  for (( i=1; i < num_remotes; i+=2 )); do
    remote_url="${remote_urls_arr[i]}"

    if [[ -n "$SSH_GIT_AUTH_USER" ]]; then
      remote_url="${remote_url//\{\{SSH_GIT_AUTH_USER\}\}/$SSH_GIT_AUTH_USER}"
    fi

    remote_url="${remote_url//\{\{REPO_OWNER\}\}/$repo_owner}"
    remote_url="${remote_url//\{\{REPO\}\}/$repo}"

    remote_urls_arr[i]="$remote_url"
  done

  call git init || return 255

  for (( i=0; i < num_remotes; i+=2 )); do
    if git remote get-url "${remote_urls_arr[i]}" >/dev/null 2>&1; then
      call git remote set-url "${remote_urls_arr[i]}" "${remote_urls_arr[i+1]}"
    else
      call git remote add "${remote_urls_arr[i]}" "${remote_urls_arr[i+1]}"
    fi
  done

  return 0
}

# shortcut
function git_i()
{
  git_init "$@"
}

if [[ -z "$BASH_LINENO" || BASH_LINENO[0] -eq 0 ]]; then
  # Script was not included, then execute it.
  git_init "$@"
fi

fi
