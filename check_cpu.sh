#!/bin/ksh


TODAY=`date +"%Y""%m""%d"`
TIME=`date +"%Y""/""%m""/""%d""    ""%H"":""%M"":""%S"`
LOGFILE="$DMS_HOME/log/check_c00503_cpu.$TODAY"

Check_child_cpu_usage()
{
#check number of child process running for each c00503 program
set -A PID `ps -eaf | grep $NUM_OF_PROCESS\
           | grep -vE "grep|vi|more|view|c00503" | awk '{print $2}'`

if [ "$PID" != "" ]
then
    for NUM_OF_CHILD_PROCESS in $PID
    do
        set -A CCPU `top -b -n 1 -p ${PID} | tail -1`

        #if cpu usage of c00503's child process is more than 85%
        #or cpu usage of c00503 process is more than 85%
        #kill c00503's child process

        if [ "${CCPU[8]}" -gt 85 ] || [ "$2" = 1 ]
        then
            echo -e                            >> $LOGFILE
            echo $TIME                         >> $LOGFILE
            echo 'User ID      : '${CCPU[1]}   >> $LOGFILE
            echo 'Program      : '${CCPU[11]}  >> $LOGFILE
            echo 'PID          : '${PID}       >> $LOGFILE
            echo 'CPU USAGE    : '${CCPU[8]}   >> $LOGFILE
            killit -15 ${PID}                  >> $LOGFILE
        fi
    done
fi
}

Check_c00503_cpu_usage()
{
#check number of c00503 program running
set -A PPID `ps -eaf | grep c00503\
              | grep -vE "grep|vi|more|view|check_c00503_cpu"\
                                                 | awk '{print $2}'`

if [ "$PPID" != "" ]
then
    for NUM_OF_PROCESS in $PPID
    do
        set -A CPU `top -b -n 1 -p $NUM_OF_PROCESS | tail -1`

        #If cpu uasge for c00503 greater than 85%
        #check child process and kill both the process

        if [ "${CPU[8]}" -gt 85 ]
        then
            echo -e                                  >> $LOGFILE
            echo $TIME                               >> $LOGFILE
            echo 'User ID      : '${CPU[1]}          >> $LOGFILE
            echo 'Program      : '${CPU[11]}         >> $LOGFILE
            echo 'C00503 PID   : '$NUM_OF_PROCESS    >> $LOGFILE
            echo 'CPU USAGE    : '${CPU[8]}          >> $LOGFILE
            Check_child_cpu_usage $NUM_OF_PROCESS 1  >> $LOGFILE
            killit -15 $NUM_OF_PROCESS               >> $LOGFILE
            break
        fi
        Check_child_cpu_usage $NUM_OF_PROCESS 0
    done
fi
}



#MAIN STARTS
log_dmsprocess $START_PROCESS check_c00503_cpu $PPID "Start check_c00503_cpu"

#check c00503 cpu usage 
Check_c00503_cpu_usage

log_dmsprocess $END_PROCESS check_c00503_cpu $PPID "End check_c00503_cpu"
