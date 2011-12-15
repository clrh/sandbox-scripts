#!/bin/bash
#Author : Hemanth H.M
#Licence : GNU GPLv3

sleeping_time=900
interval=1


# Make directory to store the results
function setdir() {
    mkdir -p Stats
    cd Stats
}

# Usage
function show_help() {

    echo "Usage is $0 a|m|n|c|h"
    echo "-a or --all to plot cpu(c),mem(m), net(n) and load(l)"
    echo "--show-create to show hot to create plot from .dat file"
    echo "--rebuild date : to rebuild all images with the specified date";
}

date=`perl -e 'use POSIX qw(strftime);print strftime "%H:%M:%S_%d-%m-%Y", localtime'`

function show_create() {

    set_data 'cpu'
    print_create
    set_data 'mem'
    print_create
    set_data 'net'
    print_create
    set_data 'load'
    print_create

}

function print_create() {
echo "gnuplot << EOF
set terminal \"$fileType\"
set output \"$output\"
set title  \"$title\"
set xlabel \"$xlabel\"
set xdata  time
set ylabel \"$ylabel\"
set timefmt \"%d-%m %H:%M:%S\"
set format x \"%H:%M\"
plot ${plot[*]}
EOF";

}

out () {
printf "\nI'm dying ..."
}
trap out SIGINT

# Use dstat to get the data set
function gendata(){
    echo "Collecting stats for $sleeping_time sec with an interval of $interval sec"
    dstat --float -tmncl 1 > ${date}_dstat.dat&
    [ "$?" -ne 0 ] && echo "Please check if you have installed dstat" && exit 1
    sleep 190s
    exec 2>/dev/null
    kill $! >/dev/null 2>&1
    #Remove the headers
    sed -e '1,2d' -e 's/B//g' -e 's/|/ /g' ${date}_dstat.dat | perl -pe 's#([0-9]+)k#$1/1024#eg' > ${date}_stat.dat
}

function rebuild() {
    setdir
    date=$1
    plotcpu
    plotmem
    plotnet
    plotload
}

function collect_data() {
    setdir
    gendata
    wait
}

# Use GNU plot to plot the graph
function graph (){
gnuplot << EOF
set terminal "$fileType"
set output "$output"
set title  "$title"
set xlabel "$xlabel"
set xdata  time
set ylabel "$ylabel"
set timefmt "%d-%m %H:%M:%S"
set format x "%H:%M"
plot ${plot[*]}
EOF
}

function set_data() {
    case "$1" in
    'cpu')
        fileType="png"
        output="${date}_cpu.png"
        title="cpu-usage"
        xlabel="time"
        ylabel="percent"
        plot=( "\"${date}_stat.dat\"" using 1:10 title '"system"' with lines,"\"${date}_stat.dat\"" using 1:9 title '"user"' with lines,"\"${date}_stat.dat\"" using 1:11 title '"idle"' with lines )
        ;;
    'mem')
        fileType="png"
        output="${date}_memory.png"
        title="memory-usage"
        xlabel="time"
        ylabel="size(Mb)"
        plot=( "\"${date}_stat.dat\"" using 1:3 title '"used"' with lines,"\"${date}_stat.dat\"" using 1:4 title '"buff"' with lines, "\"${date}_stat.dat\"" using 1:5 title '"cach"' with lines,"\"${date}_stat.dat\"" using 1:6 title '"free"' with lines )
        ;;
    'net')
        fileType="png"
        output="${date}_network.png"
        title="network-usage"
        xlabel="time"
        ylabel="size(k)"
        plot=( "\"${date}_stat.dat\"" using 1:8 title '"sent"' with lines,"\"${date}_stat.dat\"" using 1:7 title '"recvd"' with lines )
        ;;
    'load')
        fileType="png"
        output="${date}_load.png"
        title="load-usage"
        xlabel="time"
        ylabel="value"
        plot=( "\"${date}_stat.dat\"" using 1:15 title '"1m"' with lines,"\"${date}_stat.dat\"" using 1:16 title '"5m"' with lines, "\"${date}_stat.dat\"" using 1:17 title '"15m"' with lines )
        ;;
    esac

}

# Plot CPU usage 
function plotcpu() {

    set_data 'cpu';
    # Using an arry presrving the '"quotes"' is very much nessary 

    graph

}

# Plot memory usage
function plotmem() {

    set_data 'mem';

    graph
}

# Plot network usage
function plotnet() {

    set_data 'net';

    graph
}

function plotload() {

    set_data 'load';

    graph
}

# Clean up all the collected stats 
function clean(){
    echo "Cleaning"
    cd Stats
    rm -r *.dat
    echo "Done!"
}


# Loop for different options
while [[ $1 == -* ]]; do
    case "$1" in
        -h|--help|-\?) show_help; exit 0;;
        -a|--all) collect_data ; plotcpu ; plotmem ; plotnet ; plotload ; exit 0;;
        -m|--mem) collect_data ; plotmem ; exit 0 ;;
        -n|--net) collect_data ; plotnet ; exit 0 ;;
        -c|--cpu) collect_data ; plotcpu ; exit 0 ;;
        -l|--load) collect_data ; plotload ; exit 0 ;;
        -s|--show) show_create ; exit 0;;
        -r|--rebuild) rebuild $2; exit 0;;
        --) shift; break;;
        -*) echo "invalid option: $1"; show_help; exit 1;;
    esac
done

show_help; exit 1;

