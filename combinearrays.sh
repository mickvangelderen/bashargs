#!/bin/sh
#Combine or concatenating arrays in Bash
# Source : http://tldp.org/LDP/abs/html/arrays.html

# Subscript packed.
declare -a arrA=( A1 B1 C1 )

echo "____________"
echo "Array arrA"
echo "____________"
for (( i = 0 ; i < 3 ; i++ ))
do
echo "Element [$i]: ${arrA[$i]}"
done

# Subscript sparse ([1] is not defined).
declare -a arrB=( [0]="spaaa  a a ace" [2]=C2 [3]=D2 )

echo "____________"
echo "Array arrB"
echo "____________"
for (( i = 0 ; i < 4 ; i++ ))
do
echo "Element [$i]: ${arrB[$i]}"
done

declare -a arrayX

#Combine arrA and arrB
arrayX=( "${arrA[@]}" "${arrB[@]}" )

echo "____________"
echo "Array arrayX"
echo "____________"
echo "${arrayX[@]}"

cnt=${#arrayX[@]}

echo "____________"
echo "Array arrayX"
echo "____________"
for (( i = 0 ; i < cnt ; i++ ))
do
echo "Element [$i]: ${arrayX[$i]}"
done

