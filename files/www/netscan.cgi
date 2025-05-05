#!/usr/bin/haserl
content-type: text/plain
<%
  # Run scanimage wih very little interferance
  set - '' ; shift # Empty arg list...

  urldecode() {
    echo "$*" | awk '
    function gen_url_decode_array(i, n, c) {
	delete decodeArray
	for (i = 32; i < 64; ++i) {
	    c = sprintf("%c", i)
	    n = sprintf("%%%02X", i)
	    decodeArray[n] = c
	    decodeArray[tolower(n)] = c
	}
    }

    function decode_url(url, dec, tmp, pre, mid, rep) {
	tmp = url
	while (match(tmp, /%[0-9a-zA-Z][0-9a-zA-Z]/)) {
	    pre = substr(tmp, 1, RSTART - 1)
	    mid = substr(tmp, RSTART, RLENGTH)
	    rep = decodeArray[mid]
	    dec = dec pre rep
	    tmp = substr(tmp, RSTART + RLENGTH)
	}
	return dec tmp
    }

    BEGIN {
	gen_url_decode_array()
    }

    {
	print decode_url($0)
    }
    '
  }

  [ -z "$QUERY_STRING" ] && QUERY_STRING='help'
  set - '' ; shift # Empty arg list...
  QUERY_STRING=$(echo "$QUERY_STRING" | tr ';' '&')
  oIFS="$IFS" ; IFS="&"
  npqs=false
  sderr=false
  for keyw in ${QUERY_STRING}
  do
    IFS="$oIFS"
    keyw="$(urldecode "$keyw")"
    if $npqs ; then
      set - "$@" "$keyw"
      continue
    fi

    case "$keyw" in
    # Sanity checks
    npqs)
      npqs=true # Non-parsed query string... (not the best security practice!)
      continue
      ;;
    stderr)
      stderr=true # Include stderr in the output
      continue
      ;;
    stderr=hdr)
      stderr=hdr
      continue
      ;;
    d|d=*|device-name*) continue ;; # Do not allow to specify device name...
    i|i=*|icc-profile*) continue ;; # Prevent icc profiles in TIFF
    f|f=*|formatted-device-list*) continue ;; # Too complicated to implement
    b|b=*|batch*) continue ;; # Disable batch related stuff
    accept-md5-only) continue ;; # Doesn't make sense
    p|p=*|progress*) continue ;; # Nice, but will not work here...
    o|o=*|output-file*) continue ;;  # Do not write files
    scan) continue ;; # Just a place holder
    *=*)
      # Accept these...
      k="$(echo "$keyw" | cut -d= -f1)"
      v="$(echo "$keyw" | cut -d= -f2-)"
      if [ $(expr length "$k") -eq 1 ] ; then
	k="-$k"
      else
	k="--$k"
      fi
      set - "$@" "$k" "$v"
      ;;
    *)
      if [ $(expr length "$keyw") -eq 1 ] ; then
	keyw="-$keyw"
      else
	keyw="--$keyw"
      fi
      set - "$@" "$keyw" ;;
    esac
  done
  if [ "$stderr" = "hdr" ] ; then
    # Return stderr in the header...
    out=$(mktemp)
    (
      exec 2>&1 >"$out"
      scanimage "$@"
    ) | (
    set -x
    echo "X-TMP: $out"
    while read line
    do
      if [ -z "$line" ] ; then
	echo "X-STDERR-WAIT: ."
      else
	echo "X-STDERR_OUT: $line"
      fi
    done)
    echo ''
    cat "$out"
    rm -f "$out"
    exit 0
  fi
  $stderr && exec 2>&1
  echo ''
  scanimage "$@"
%>
