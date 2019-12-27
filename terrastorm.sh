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

# Some vars
strVarFiles=''; strStateFiles=''; strLastArg=''; strExtraArgs=''; strFinalCall='';

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
case $3 in
  (init)
    # Nothing special. Could probably be added?
  ;;

  (import|plan|apply|destroy|state|taint|untaint)
    # gather the command, organisation and environment inputs
    org=$1
    env=$2
    cmd=$3
    shift 3

    # Special modifications (EG: for state command)
    case $cmd in
      (state)
      # get the second command parameter (list,mv,pull,push,rm,show)
        opr=$1
        shift 1
        case $opr in
          # check that we support the command
          (rm)
            # ok
          ;;
          (*)
            echo "Unsupported state command ["${opr}"] ... exiting ...\n"; exit 1;
          ;;
        esac
      ;;
      (*)
      ;;
    esac

    # Add the tfvars files for the requested datacentre/environment
    for file in "config/${org}/${env}"/*.tfvars
    do
      if [ -f "$file" ];then
        strVarFiles=${strVarFiles}"-var-file ${file} "
      fi
    done

    # load the tfvars common to all envs
    for file in "config/shared/all"/*.tfvars
    do
      if [ -f "$file" ];then
        strVarFiles=${strVarFiles}"-var-file ${file} "
      fi
    done

    # Add the state file for the requested datacentre/environment
    strStateFiles="-state state/${org}/${env}/${env}.tfstate "

    # ------------------------------------------------------------------------------------------------

    case $cmd in
      (import)
        # We'll just relay all the remaining parameters through
        eval strExtraArgs="\${@}";

        strFinalCall="${cmd} ${strVarFiles}${strStateFiles}${strExtraArgs}"
      ;;

      (state|taint|untaint) 
        # add the command and the operator together
        cmd="${cmd} ${opr}"

        # Relay all the remaining parameters through
        eval strExtraArgs="\${@}";

        strFinalCall="${cmd} ${strStateFiles}${strExtraArgs}"
      ;;

      (plan|apply|destroy)
        # All but the last argument can simply be relayed through
        eval strExtraArgs="\${*%"${!#}"}";

        # The final argument (Configuration) will indicate which supplementary vars files we want to load
        eval strLastArg="\${$#}";

        # This is a custom filter for terraform configurations I use. You may want to remove this section ...
        # ... or further customise it for your needs.
        case $strLastArg in
          ("datacentre"|"datacentre/"|"environment"|"environment/")

            # load the tfvars common to environments or datacentres accordingly
            for file in "config/shared/${strLastArg%/}"/*.tfvars
            do
              if [ -f "$file" ];then
                strVarFiles=${strVarFiles}"-var-file ${file} "
              fi
            done
          ;;
          (*)
            echo "Unknown configuration, did you make a typo? ... exiting ...\n"; exit 1;
          ;;
        esac
      
        strFinalCall="${cmd} ${strVarFiles}${strStateFiles}${strExtraArgs}${strLastArg}"
      ;;
    esac

    # ------------------------------------------------------------------------------------------------
  ;;

  (*)
    echo "Unsupported command for script, exiting ...\n"; exit 1;
  ;;
esac
# --------------------------------------------------------------------------------------------------

echo '--------------------------------------------------------------------------------------------------'
printf "configuration : ${strLastArg} \n";
printf "extra args    : ${strExtraArgs} \n";
echo '--------------------------------------------------------------------------------------------------'
printf "executing     :\n";
printf " $ terraform ${strFinalCall} \n";
echo '--------------------------------------------------------------------------------------------------'

cmd() {
  terraform ${strFinalCall}
}

cmd

exit 0
