#!/bin/sh
if [ $# -gt 0 ] ; then
  if type "$1" >/dev/null 2>&1 ; then
    exec "$@"
    exit $?
  fi
  echo "Ignoring command line arguments"
  echo "	$*"
fi

# Set-up TZ
if [ -n "${TZ:-}" ] ; then
  ln -sf /usr/share/zoneinfo/$TZ /etc/localtime
  echo "$TZ" > /etc/timezone
fi

# Make sure we have network connectivity
gw=$(route -n | awk '$1 == "0.0.0.0" { print $2 }')
wait_time=600
cnt=0
net_up=false
while [ $cnt -lt $wait_time ]
do
  cnt=$(expr $cnt + 1)
  if ping -c 1 $gw ; then
    net_up=true
    break
  fi
  sleep 1
done
if ! $net_up ; then
  echo "Time-out waiting for network"
  exit 1
fi

# Configure Printer administrator
if ! grep -q "^$USER_NAME:" /etc/passwd ; then
  enc_passwd=$(echo "$USER_PASSWD" | openssl passwd -stdin -5)
  useradd -ms /bin/bash -G lpadmin -p "$enc_passwd" "$USER_NAME"
fi

setup-printer

exec supervisord

#~ if type /bin/bash ; then
  #~ exec /bin/bash -il
#~ else
  #~ exec /bin/sh -il
#~ fi

