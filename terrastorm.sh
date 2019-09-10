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

# Check for script dependencies
for i in "bash" "jq"
do
  if ! dep_loc="$(type -p "$i")" || [[ -z $dep_loc ]]; then
    echo "Error: this script needs the ["$i"] package which is not installed." >&2
    echo "Exiting..." >&2
    exit 1
  fi
done

# --------------------------------------------------------------------------------------------------
case $1 in
  (init)
    # Nothing special. Could probably be added?
  ;;

  (import|plan|apply|destroy)
    # gather the command, organisation and environment inputs
    cmd=$1
    org=$2
    env=$3
    shift 3

    # Add the tfvars files for the requested datacentre/environment
    for file in "config/${org}/${env}"/*.tfvars
    do
      if [ -f "$file" ];then
        strVarFiles=${strVarFiles}'-var-file="'${file}'" '
      fi
    done

    # load the tfvars common to all envs
    for file in "config/shared/all"/*.tfvars
    do
      if [ -f "$file" ];then
        strVarFiles=${strVarFiles}'-var-file="'${file}'" '
      fi
    done

    # Add the state file for the requested datacentre/environment
    strStateFiles='-state="state/'${org}'/'${env}'/'${env}'.tfstate" '

    # ------------------------------------------------------------------------------------------------

    case $cmd in
      (import) # easy mode

        # We'll just relay all the remaining parameters through
        eval strExtraArgs=\$@;
      ;;

      # (state) 
      #   # gather the (command) operation input
      #   opr=$1
      #   shift 1

      #   # relay all the remaining parameters (object identifiers) through
      #   eval strExtraArgs=\$@;
      # ;;

      (plan|apply|destroy) # hard mode :-D

        # All but the last argument can simply be relayed through
        eval strExtraArgs=\${*%${!#}};

        # The final argument (Configuration) will indicate which supplementary vars files we want to load
        eval strLastArg=\${$#};

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
          echo "Unknown configuration, did you make a typo? ... exiting ...\n"; exit 1;;
        esac
      ;;
    esac

    # ------------------------------------------------------------------------------------------------
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
