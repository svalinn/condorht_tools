#!/bin/bash

file_token=$1
unit_name=$2
file_type=$3
output_name=$4

# check for args
if [[ $# -eq 0 ]] ; then
    echo 'No arguments provided'
    exit 1
fi

if [ $# -gt 0 ] && [ $# -lt 4 ] ; then
    echo 'Not enough arguments provided'
    exit 1
fi

if [[ $# -gt 4 ]] ; then
    echo 'Too many arguments provided'
    exit 1
fi

file_match=$file_token"*"$unit_name
files=()

# get all the matching files
for file in $file_match ; do
    files+=($file)
done

# get the number of files
len=${#files[@]}

# check for files
if [ $len -eq 0 ] ; then
    echo "no files that match token, " $file_token
fi

# otherwise write the job file
for (( i = 0 ; i < $len ; i++ )) ; do
    echo ${files[$i]} >> instructions
#    echo ${files[$i]}
done
echo " " >> instructions
echo $file_token"_"$2 >> instructions

# process the file
if [ $file_type == "usrbin" ] ; then
    $FLUPRO/flutil/usbsuw < instructions
fi
if [ $file_type == "usrtrack" ] ; then
    $FLUPRO/flutil/ustsuw < instructions
fi
if [ $file_type == "usrbdx" ] ; then
    $FLUPRO/flutil/usxsuw < instructions
fi
if [ $file_type == "resnuclei" ] ; then
    $FLUPRO/flutil/usrsuw < instructions
fi
if [ $file_type == "yield" ] ; then
    $FLUPRO/flutil/usysuw < instructions
fi

# cleanup
rm instructions
