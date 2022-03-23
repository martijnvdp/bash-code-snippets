#!/usr/bin/env bash

rootDir=$(git rev-parse --show-toplevel)

for variable_file in $(find $rootDir |grep variables.tf); 
do
    cat $variable_file | awk -f $rootDir/scripts/sort_tf_files.awk | tee $variable_file.sorted
    cp $variable_file.sorted $variable_file
    rm $variable_file.sorted
done
