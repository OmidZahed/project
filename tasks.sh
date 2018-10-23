#!/bin/bash
cd $HOME
if [[ ! -d TASK_MANAGER_0.01 ]]; then 
        mkdir TASK_MANAGER_0.01
        cd ASK_MANAGER_0.01
        mkdir ACTIONS 
        mkdir pomodoro
        
    else 
        cd TASK_MANAGER_0.01
        if [[ ! -d ACTIONS ]];then 
            mkdir ACTIONS
        fi
        if [[ ! -d pomodoro ]];then 
            mkdir pomodoro
        fi
    fi
create_log_dir (){
    dt=$(date +'%d-%m-%Y');
    if [[ -d LOG ]]; then 
        cd LOG/
        if [[ ! -d weekly ]]; then
            mkdir weekly
        fi
        if [[ -f $dt.txt ]]; then 
            rm $dt.txt 
        else
            touch $dt.txt
        fi
    else
        mkdir LOG
        cd LOG
        mkdir wkeekly
        touch $dt.txt     
    fi
    cd ..
}

get_weekly_log(){
    week=7
    i=0
    end=$(date +'%d-%m'); 
    start=$(date --date="$week day ago" +'%d-%m-%Y');
    open=0
    closed=0
    if [[ -f LOG/weekly/"$end-to-$start".txt ]]; then 
        rm LOG/weekly/"$end-to-$start".txt
    fi
    while [ $i -lt $week ]
    do 
        dt=$(date --date="$i day ago" +'%d-%m-%Y');
        while read -r line ; do
            case $line in 
                *$dt*)
                    echo $line>>LOG/weekly/"$end-to-$start".txt
                    open=$((open+1))
                    ;;
            esac 
        done <ACTIONS/opened.txt
        while read -r line ; do
            case $line in 
                *$dt*)
                    echo $line >>LOG/weekly/"$end-to-$start".txt
                    closed=$((closed+1))
                    ;;
            esac 
        done <ACTIONS/closed.txt
    i=$((i+1))
    done
    sum=$((open + closed ))
    closed=$((100*closed))
    echo ""
    echo "[$((closed/sum)) % ] of your actions closed this week" >>LOG/weekly/"$end-to-$start".txt
    less LOG/weekly/"$end-to-$start".txt
    exit
}


make_progress_bar(){
    str="["
    end=$(($1/4))
    i=0
    while [ $((i)) -lt $((end)) ]
    do
        str+="#"
        i=$((i+1))
    done
    end=$(( 25- $1/4))
    i=0
    while [ $((i)) -lt $((end)) ]
     do
        str+="-"
        i=$((i+1))
    done
    echo "$1% $str]  are closed">>LOG/$dt.txt
}
pomodoro(){
    all=$(($1)) 
    tag=$2
    #one second less than 30min
    while [[ $all -gt 0 ]]
    do
        clear 
        echo ""
        echo "[ $tag session ]"
        min=$(($all/60))
        sec=$((all - $min*60))    
        echo ""
        echo " $min:$sec "
        all=$((all-1))
        sleep 1
    done 
   echo "$tag session ended"
}

while  (($#)); do
  case $1 in
    -s|search)
        grep $2 ACTIONS/opened.txt |less
        echo ""
        exit
        ;;
    -r|read)
        less < ACTIONS/opened.txt
        exit ;;
    -t|today)
        echo "today list"
        td=$(date +'%d-%m-%Y');
        grep $td ACTIONS/opened.txt > today.txt
        less today.txt
        exit ;;
    tomtommarow)
        dt=$(date --date="1 day" +'%d-%m-%Y');
        grep $dt ACTIONS/opened.txt|less
        exit ;;
    -a|add)
        count=($( tail -1 ACTIONS/opened.txt ))
        count=$(($count+1))
        if [ -n $3 ]; then
          case $2 in
            -d )
                dt=$(date --date="$3 day" +'%d-%m-%Y');
                echo "$((count))" "] [$dt] : $4 ." >> ACTIONS/opened.txt
                echo "task added"
                exit;;
            -w )
                dt=$(date --date='$3 week' +'%d-%m-%Y');
                echo "$((count)) ] [$dt] : $4 ." >> ACTIONS/opened.txt
                echo "task:: $((count))] $4   added"
                exit ;;
          esac
        fi
        if [ -z $3]; then
              dt=$(date +'%d-%m-%Y');
              echo "$((count)) ] [$dt] : $2  ." >> ACTIONS/opened.txt
              echo "task added"
        fi
        exit
        ;;
    -c|close )
                echo $2
                dt=$(date +'%d-%m-%Y');
                while read line; do
                  case $line in
                    "$2 ]"*)
                        echo "$line closed [$dt]" >> ACTIONS/closed.txt
                        sed -i -e "/$2 ]/d" ACTIONS/opened.txt
                        echo "$line task closed at [$dt]"
                        exit
                      ;;
                  esac
                done <ACTIONS/opened.txt
        exit ;;
    -l|log)
        dt=$(date +'%d-%m-%Y');
        create_log_dir 
        case $2 in 
            -t|t|today )
                open=0
                closed=0
                dt=$(date +'%d-%m-%Y');
                while read -r line ; do
                    case $line in 
                        *$dt*)
                            echo $line>>LOG/$dt.txt
                            open=$((open+1))
                            ;;
                    esac 
                done <ACTIONS/opened.txt
                while read -r line ; do
                    case $line in 
                        *$dt*)
                            echo $line >>LOG/$dt.txt
                            closed=$((closed+1))
                            ;;
                    esac 
                done <ACTIONS/closed.txt
            sum=$((open + closed ))
            closed=$((100*closed))
            make_progress_bar $((closed /sum))
            less LOG/$dt.txt
            ;;


            -w|w|week)
                get_weekly_log 
                ;;


        esac
            exit ;;

    -h|help )
            echo """ This is  task manager version 0.01
    Usage:
        for more help read README.md on < github >
    -a      add  'task name ' for add task to list
                (to add task in specific date use ::
            -a -d <int number> 'task' )
                (e.g : -a -d 1 'call ...' for tomarrow_
            -w for week (useage is like -d )
    
    -gui        GUI interface 
    -l <?>  log       gives log to user (weekly log )
        <t or w > for today or this week

    -s      search < phrease >  searches for phrease in files 
    -r      read      showes open tasks  tasks list
    tom    tommarow   showes tommarows tasks 
    -t      today     shows today's task list
    -p      pomodoro  pomodoro technique
        usage : -p   <massage>
    -h      --Help      showes this message"""
            exit
          ;;
    -p|pomodoro)
            pomodoro 1798 $2
            # 1800 is 30 min
            notify-send "$tag session (30min) ended "
            dt=$(date +'%d-%m-%Y');
            echo "[$tag ]session Done." >> pomodoro/$dt.txt
        exit
        ;;
    *) 
        echo "READ -h or help section first"
        exit 200
        ;;
    esac
done
