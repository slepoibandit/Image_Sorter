#!/bin/bash

# Arguments support, under construction
# passed_args=$1
#
# if [[ -n $passed_args ]]
# then
# echo "You passed these arguments: $passed_args. Arguments support is under construction."
# fi

#Make the desired folder choice interactive later on
FOLDER=./
cd $FOLDER
#clean up the error list
rm -f err_list
rm -f saved_list.txt
touch err_list
touch saved_list.txt

#Read image-only filenames and write them to the saved_list.txt
ls *jpg 2>/dev/null
if [[ $? == 0 ]]
then ls -1 *jpg 2>>err_list >> saved_list.txt
fi
ls *jpeg 2>/dev/null
if [[ $? == 0 ]]
then ls -1 *jpeg 2>>err_list >> saved_list.txt
fi
ls *png 2>/dev/null
if [[ $? == 0 ]]
then ls -1 *png 2>>err_list >> saved_list.txt
fi
ls *gif 2>/dev/null
if [[ $? == 0 ]]
then ls -1 *gif 2>>err_list >> saved_list.txt
fi

if [[ $(head err_list) == '' ]]
then
  echo "The list of file names is saved at saved_list.txt in the images folder."
else
  echo "There was an error while saving the list of file names: $(head err_list)"
fi

#bug: hyphen at the start of the names seems to break the script!
#replace symbols, numbers and extensions with newlines
sed -i -r -e 's/\.(jpg|jpeg|png|gif)//gi' saved_list.txt #strip extensions
sed -i -r -e 's/(\-|_|[0-9]|\&)/\n/gi' saved_list.txt #break by symbols and numbers delimeters to newlines
sed -i -r -e '/^\s*$/d' saved_list.txt #clean up whitespaces
sed -i -r -e 's/./\L&/gi' saved_list.txt #lowercase all letters
sed -i -r -e '/\b.{1,2}\b/d' saved_list.txt #remove 1-2 lettered words

#sorting and building frequency list
sort -o saved_list.txt saved_list.txt #sort lines into alphabetical order
uniq -c -d saved_list.txt freq_list.txt #build frequency list and remove unique items
sort -n -r -o saved_list.txt freq_list.txt #sort words based on frequencies

#create folders based on the generated freq list
INCREM=1
while [[ $(sed -n -e ${INCREM}p saved_list.txt) ]]; do
  WORDFROMLIST=$(sed -n -e ${INCREM}p saved_list.txt | sed -r -e 's/([0-9]|\s)//gi')
  mkdir -p $WORDFROMLIST
  INCREM=$((INCREM+1))
done
unset WORDFROMLIST
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
unset WORDFROMLIST
#clean up empty directories, that have lost the contest (e.g. animal folder over wolf folder in animal-wolf.jpg due to higher frequency of animal folder)
ls --file-type --ignore="*.*" | grep "/" > deleted.txt #keep a list of all items that were removed for future optimizations
rm -d -f $(ls --file-type --ignore="*.*" | grep "/") #WARNING! EXPERIMENTAL, COULD LOSE FILES
#delete all temporary files
rm -f freq_list.txt
rm -f saved_list.txt
rm -f err_list
#Return to the previous current directory
cd -
