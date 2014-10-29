# Navigate to the output folder
cd data

# CPS has a bug that it doesn't recognize column names
# because they within quotation marks.
# 1i tells sed to insert the text that follows at line 1 of the file;
# don't forget the \ newline at the end so that the existing line 1 is moved to line 2.
sed -i -e '1iHere is my new top line\' dataset.csv
sed -i -e '1iHere is my new top line\' indicator.csv
sed -i -e '1iHere is my new top line\' value.csv
