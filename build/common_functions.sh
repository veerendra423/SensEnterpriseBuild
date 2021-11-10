#!/bin/bash 
#
#

if [[ -n "${SENS_RELEASE_VERSION}" ]]
then
    echo "Installing RELEASE "$SENS_RELEASE_VERSION
else
    # If a local dev-snapshot is used (ie no SENS_RELEASE_VERSION is defined, we print a warning)"
    echo "WARNING : RELEASE not defined!"
fi

export TERM=vt100
DEBUG=1
echo_debug()
{
   if [ $DEBUG -ne 0 ]
   then
      echo -e $@
   fi
}

echo_header()
{
	echo -e "\e[1;31m $@ \e[0m"
}


# Set the default ARCH
# This is set by default to x86_64
if [ x${ARCH} = xx86_64 ]
then
    echo_debug "Environment-specified ARCH as x86_64"
else
    echo_debug "Environment did not specify ARCH, setting default of x86_64"
    ARCH="x86_64"
fi

# Globals
TARGETLISTFILE=targets
SERVICELISTFILE=services
RELPREFIX="VERSION"

check_target_arg()
{  
    TARGET=$1
    VER_REGEX="${RELPREFIX}_[[:digit:]]{1,}(.[[:digit:]]{1,}){1,}"
    if echo ${TARGET} | egrep "^${VER_REGEX}" >/dev/null 
    then
      #echo_debug $(echo ${TARGET} | egrep "^${VER_REGEX}")
      echo_debug ""
    else
      echo "version format should be $VER_REGEX"
      exit 1 
    fi
}

check_command_arg()
{
    #echo "Enter check command"
    TARGET=$1
    if echo ${TARGET} | grep -w -e 'build' -e 'update' -e 'push' -e 'lock' -e 'unlock'  -e 'help' -e 'clean' -e 'tag'  >/dev/null 
    then
      #echo_debug "Command: ${TARGET}"
      return 0
    else
      #echo_debug "Command not found: ${TARGET}"
      return 1 
    fi
}

check_subcommand_arg()
{
    #echo "Enter check subcommand"
    TARGET=$1
    if echo ${TARGET} | grep -w -e 'push' >/dev/null 
    then
      #echo "Subcommand: ${TARGET}"
      return 0
    else
      #echo "Subcommand not found: ${TARGET}"
      return 1 
    fi
}
