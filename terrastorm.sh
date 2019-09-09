#!/usr/bin/env bash
##
## SYNOPSIS
##   A terraform wrapper script optimising for multi-environment and multi-tfvars-file inputs
## NOTES
##   Author: https://github.com/davidsuart
##   License: MIT License (See repository)
##   Requires:
##     - bash, jq
## LINK
##   Repository: https://github.com/davidsuart/terrastorm
##

# --------------------------------------------------------------------------------------------------
#
#  IMPORTANT:
#    - Successful operation depends on a compatible terraform config layout. See the repo for details.
#    - The script will output LOCAL state.
#
# --------------------------------------------------------------------------------------------------

strVarFiles=''
strStateFiles=''
strLastArg=''
strExtraArgs=''

# --------------------------------------------------------------------------------------------------
case $1 in
  (plan|apply|destroy)
  # gather the command, datacentre and environment inputs
  cmd=$1
  dtc=$2
  env=$3
  shift 3

  # load the tfvars common to all envs
  for file in "config/shared/all"/*.tfvars
  do
    if [ -f "$file" ];then
      strVarFiles=${strVarFiles}'-var-file="'${file}'" '
    fi
  done

  # All but the last argument can simply be relayed through
  eval strExtraArgs=\${*%${!#}};

  # The final argument (Configuration) will indicate which supplementary vars files we want to load
  eval strLastArg=\${$#};

  # ------------------------------------------------------------------------------------------------
  case $strLastArg in
    ("datacentre"|"datacentre/"|"environment"|"environment/")

    # load the tfvars common to environments or datacentres accordingly
    for file in "config/shared/${strLastArg%/}"/*.tfvars
    do
      if [ -f "$file" ];then
        strVarFiles=${strVarFiles}'-var-file="'${file}'" '
      fi
    done

    ;;
    (*)
    echo "Unsupported command for script, exiting ...\n"; exit 1;;
  esac

  # Add the tfvars files for the requested datacentre/environment
  for file in "config/${dtc}/${env}"/*.tfvars
  do
    if [ -f "$file" ];then
      strVarFiles=${strVarFiles}'-var-file="'${file}'" '
    fi
  done

  # Add the state file for the requested datacentre/environment
  strStateFiles='-state="state/'${dtc}'/'${env}'/'${env}'.tfstate" '

  # ------------------------------------------------------------------------------------------------
  ;;

  ######### THIS NEEDS TO BE REVISITED!!! #############
  (import)
  # gather the command
  cmd=$1
  dtc=$2
  env=$3
  shift 3

  # load the tfvars common to all envs
  for file in "config/shared/all"/*.tfvars
  do
    if [ -f "$file" ];then
      strVarFiles=${strVarFiles}'-var-file="'${file}'" '
    fi
  done

  # Add the tfvars files for the requested datacentre/environment
  for file in "config/${dtc}/${env}"/*.tfvars
  do
    if [ -f "$file" ];then
      strVarFiles=${strVarFiles}'-var-file="'${file}'" '
    fi
  done

  # All but the last argument
  eval strExtraArgs=\${*%${!#}};

  # The final argument
  eval strLastArg=\${$#};

  # Add the state file for the requested datacentre/environment
  strStateFiles='-state="state/'${dtc}'/'${env}'/'${env}'.tfstate" '

  ######### THIS NEEDS TO BE REVISITED!!! #############
  ;;

  (*)
  echo "Unsupported command for script, exiting ...\n"; exit 1
  ;;
esac
# --------------------------------------------------------------------------------------------------

echo '--------------------------------------------------------------------------------------------------'
echo configuration : ${strLastArg}
echo extra args    : ${strExtraArgs}
echo '--------------------------------------------------------------------------------------------------'
echo executing     :
echo "> $ terraform" "${cmd}" "${strVarFiles}""${strStateFiles}""${strExtraArgs}""${strLastArg}"
echo '--------------------------------------------------------------------------------------------------'

cmd() {
  eval terraform "${cmd}" "${strVarFiles}""${strStateFiles}""${strExtraArgs}""${strLastArg}"
}

cmd

exit 0
