#!/bin/bash

set -e

createKeyFile() {
  local SSH_PATH="$HOME/.ssh"

  mkdir -p "$SSH_PATH"
  touch "$SSH_PATH/known_hosts"

  echo "$INPUT_KEY" > "$SSH_PATH/id_rsa"

  chmod 700 "$SSH_PATH"
  chmod 600 "$SSH_PATH/known_hosts"
  chmod 600 "$SSH_PATH/id_rsa"

  eval $(ssh-agent)
  ssh-add "$SSH_PATH/id_rsa"

  ssh-keyscan -t rsa "$INPUT_HOST" >> "$SSH_PATH/known_hosts"
}

executeSSH() {
  local USEPASS=$1
  local LINES=$2
  local COMMAND=""

  # holds all commands separated by semi-colon or keep "&&"
  local COMMANDS=""

  # this while read each commands in line and
  # evaluate each line against all environment variables
  while IFS= read -r LINE; do
    LINE=$(echo $LINE)
    if [[ -z "${LINE}" ]]; then
      continue
    fi
    COMBINE="&&"
    LASTCOMBINE=""
    if [[ $LINE =~ ^.*\&\&$ ]];  then
      LINE="$LINE true"
      LASTCOMBINE="&&"
    elif [[ $LINE =~ ^\&\&.*$ ]];  then
      LINE="true $LINE"
    elif [[ $LINE =~ ^.*\|\|$ ]]; then
      LINE="$LINE false"
      LASTCOMBINE="||"
    elif [[ $LINE =~ ^\|\|.*$ ]]; then
      LINE="false $LINE"
      COMBINE="||"
    fi
    LINE=$(eval 'echo "$LINE"')
    if ! [[ $LINE =~ ^\(.*\)$ ]];  then
      LINE=$(eval echo "$LINE")
    else
      LINE="${LINE}"
    fi
    LINE="$LINE $LASTCOMBINE"

    if [ -z "$COMMANDS" ]; then
      COMMANDS="$LINE"
    else
      # ref. https://unix.stackexchange.com/questions/459923/multiple-commands-in-sshpass
      if [[ $COMMANDS =~ ^.*\&\&$ ]] || [[ $COMMANDS =~ ^.*\|\|$ ]]; then
        COMMANDS="$COMMANDS ${LINE}"
      else
        COMMANDS="$COMMANDS $COMBINE ${LINE}"
      fi
    fi
  done <<< "$LINES"

  if [[ $COMMANDS =~ ^.*\&\&$ ]];  then
    COMMANDS="$COMMANDS true"
  elif [[ $COMMANDS =~ ^.*\|\|$ ]]; then
    COMMANDS="$COMMANDS false"
  fi
  echo "${COMMANDS}"

  CMD="ssh"
  if $USEPASS; then
    CMD="sshpass -p $INPUT_PASS ssh"
  fi
  $CMD -o StrictHostKeyChecking=no -o ConnectTimeout=${INPUT_CONNECT_TIMEOUT:-30s} -p "${INPUT_PORT:-22}" "$INPUT_USER"@"$INPUT_HOST" "${COMMANDS}" > /dev/stdout
}


######################################################################################

echo "+++++++++++++++++++STARTING PIPELINE+++++++++++++++++++"

USEPASS=true
if [[ -z "${INPUT_KEY}" ]]; then
  echo "+++++++++++++++++++Use password+++++++++++++++++++"
else
  echo "+++++++++++++++++++Create Key File+++++++++++++++++++"
  USEPASS=false
  createKeyFile || false
fi

if ! [[ -z "${INPUT_SCRIPT}" ]]; then
  echo "+++++++++++++++++++Pipeline: RUNNING SSH+++++++++++++++++++"
  executeSSH "$USEPASS" "$INPUT_SCRIPT" || false
fi

echo "+++++++++++++++++++END PIPELINE+++++++++++++++++++"
