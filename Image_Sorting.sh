#!/bin/bash

# Arguments support, under construction
# passed_args=$1
#
# if [[ -n $passed_args ]]
# then
# echo "You passed these arguments: $passed_args. Arguments support is under construction."
# fi

#Make the desired folder choice interactive later on
#Invoke script anywhere, work inside the current directory
SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")
echo "Script is located at: $SCRIPT_PATH"
FOLDER=./
cd $FOLDER

function removeTechnicalWords() {
  # create exclusion list if not found
  if [[ ! -f ${SCRIPT_PATH}/exclusion_list.txt ]]; then
    touch ${SCRIPT_PATH}/exclusion_list.txt
    echo "The exclusion list was not found, so the exclusion_list.txt was created automatically. Please update it manually to get better results."
  fi

  # exlude all the technical words from saved_list based on information from exclusion_list
  INCREM=1
  while [[ $(sed -n -e ${INCREM}p ${SCRIPT_PATH}/exclusion_list.txt) ]]; do
    WORDFROMLIST=$(sed -n -e ${INCREM}p ${SCRIPT_PATH}/exclusion_list.txt)
    sed -i -r -e "/\b($WORDFROMLIST)\b/d" saved_list.txt #remove technical words
    INCREM=$((INCREM+1))
  done
  unset INCREM
  unset WORDFROMLIST
}

function saveImagesList() {
  #Read image-only filenames and write them to the saved_list.txt
  ls -1 -U -- *.{jpg,jpeg,png,gif} > saved_list.txt
  echo "The list is saved successfully."
}

function buildFrequencies() {
  #replace symbols, numbers and extensions with newlines
  #bug: hyphen at the start of the names seems to break the script!
  sed -i -r -e 's/\.(jpg|jpeg|png|gif)//gi' saved_list.txt #strip extensions
  sed -i -r -e 's/(\-|_|[0-9]|\&|\.|\(|\)|,)/\n/gi' saved_list.txt #break by symbols and numbers delimeters to newlines
  sed -i -r -e '/^\s*$/d' saved_list.txt #clean up whitespaces
  sed -i -r -e 's/./\L&/gi' saved_list.txt #lowercase all letters
  sed -i -r -e '/\b.{1,2}\b/d' saved_list.txt #remove 1-2 lettered words
  removeTechnicalWords;

  #sorting and building frequency list
  sort -o saved_list.txt saved_list.txt #sort lines into alphabetical order
  uniq -c -d saved_list.txt freq_list.txt #build frequency list and remove unique items
  sort -n -r -o saved_list.txt freq_list.txt #sort words based on frequencies
  echo "List of frequencies has been built."
}

function createFolders() {
  #create folders based on the generated freq list
  INCREM=1
  while [[ $(sed -n -e ${INCREM}p saved_list.txt) ]]; do
    WORDFROMLIST=$(sed -n -e ${INCREM}p saved_list.txt | sed -r -e 's/([0-9]|\s)//gi')
    mkdir -p $WORDFROMLIST
    INCREM=$((INCREM+1))
  done
  unset INCREM
  unset WORDFROMLIST
}

function sortImages() {
  #sort images into folders starting with the most frequent filenames
  INCREM=1
  while [[ $(sed -n -e ${INCREM}p saved_list.txt) ]]; do
    WORDFROMLIST=$(sed -n -e ${INCREM}p saved_list.txt | sed -r -e 's/([0-9]|\s)//gi')
    mv -i -v -t $WORDFROMLIST $(ls *.jpg | sed -r -e 's/([0-9]|_)/\t/gi' | grep -iw "$WORDFROMLIST") # doesn't move original files
    mv -i -v -t $WORDFROMLIST $(ls *.jpeg | sed -r -e 's/([0-9]|_)/\t/gi' | grep -iw "$WORDFROMLIST") #BUGGG
    mv -i -v -t $WORDFROMLIST $(ls *.png | sed -r -e 's/([0-9]|_)/\t/gi' | grep -iw "$WORDFROMLIST")
    mv -i -v -t $WORDFROMLIST $(ls *.gif | sed -r -e 's/([0-9]|_)/\t/gi' | grep -iw "$WORDFROMLIST")
    INCREM=$((INCREM+1))
  done
  unset INCREM
  unset WORDFROMLIST
  #clean up empty directories, that have lost the contest (e.g. animal folder over wolf folder in animal-wolf.jpg due to higher frequency of animal folder)
  ls --file-type --ignore="*.*" | grep "/" > deleted.txt #keep a list of all items that were removed for future optimizations
  rm -d -f $(ls --file-type --ignore="*.*" | grep "/") #WARNING! EXPERIMENTAL, COULD LOSE FILES
}

saveImagesList;
buildFrequencies;

# #delete all temporary files
# rm -f freq_list.txt
# rm -f saved_list.txt
# rm -f err_list
# #Return to the previous current directory
# cd -
