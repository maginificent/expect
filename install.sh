#!/bin/sh

PACKAGE1="/root/work/expect/hpq_ilo.pkg"
PACKAGE2="/root/work/expect/hpq_health.pkg"
HOSTSFILE=$1
#HOSTNAME="centos1"
PROMPT="#"
i=0

if [ $# -ne 1 ] || [ ! -f $1 ] ;  then
  echo "[ERROR] Please set list file of target hosts to 1st arg."
  exit 1;
fi

while read HOSTNAME
do
  STR=`grep $HOSTNAME /etc/hosts | wc -l` 
  if [ $STR -ne 1 ]; then
    echo "[ERROR] $HOSTNAME is not in /etc/hosts."
    exit 1;
  fi
done < $HOSTSFILE

echo "HPQilo and HPQhealth will be installed to following servers."
echo "==================="
echo "TARGET SERVER"
echo ""
cat  $HOSTSFILE
echo ""
echo "Input password:"
read PW

while read HOSTNAME
do
  expect -c "
  
    spawn ssh root@$HOSTNAME
    expect {
      \"(yes/no)?\" {
        send \"yes\n\"
        exp_continue
      }
      \"password\" {
        send   \"$PW\n\"
      }
    }
    
    expect \"$PROMPT\"
    send   \"ls -l ${PACKAGE1} ${PACKAGE2}\n\"
    
    expect {
      -regexp \"cannot access.*$PROMPT\" {
        exit 1
      }
      \"$PROMPT\" {
        send   \"${PACKAGE1}\n\"
      }
    }
    expect {
      \"Select install package\" {
      send   \"\n\"
      }
      \"$PROMPT\" {
        exit 1
      }
    }
    expect {
      \"Do you create new directory\" {
        send   \"y\n\"
      }
      \"$PROMPT\" {
        exit 1
      }
    }
    
    expect {
      \"Do you really install the package\" {
      send   \"y\n\"
      }
      \"$PROMPT\" {
        exit 1
      }
    }
    expect {
      -regexp \"complete.*$PROMPT\" {
        send   \"${PACKAGE2}\n\"
      }
      \"$PROMPT\" {
        exit 1
      }
    }
    expect {
      \"Select install package\" {
        send   \"\n\"
      }
      \"$PROMPT\" {
        exit 1
      }
    }
    expect {
      \"Do you create new directory\" {
        send   \"y\n\"
      }
      \"$PROMPT\" {
        exit 1
      }
    }
    
    expect {
      \"Do you really install the package\" {
      send   \"y\n\"
      }
      \"$PROMPT\" {
        exit 1
      }
    }
    expect {
      -regexp \"complete.*$PROMPT\" {
        exit 0
      }
      \"$PROMPT\" {
        exit 1
      }
    }
  "
  
  if [ $? -eq 0 ]; then
    SUCCESS_HOSTS+=($HOSTNAME)
  else
    ERROR_HOSTS+=($HOSTNAME)
  fi

  i=`expr $i + 1`

done < $HOSTSFILE

echo ""
echo "#########################"
echo "  RESULT"
echo "#########################"

if [ $SUCCESS_HOSTS ]; then
  echo "---COMPLETE (${#SUCCESS_HOSTS[@]}/$i)---"
  echo ${SUCCESS_HOSTS[@]}
fi
if [ $ERROR_HOSTS ]; then
  echo "---FAILURE (${#ERROR_HOSTS[@]}/$i)---"
  echo ${ERROR_HOSTS[@]}
fi

echo ""

if [ $SUCCESS_HOSTS ] && [ ! $ERROR_HOSTS ]; then
  echo "HPQilo and HPQhelath were installed to all servers."
  exit 0
else
  echo "Error was occurred. Please check the result."
  exit 1
fi
