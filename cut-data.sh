#!/bin/bash
# Cut a large OSM file into pieces based on a bunch of shapefiles, each having only one polygon.
# this script was purpose-built for the Allegheny County building import, hastily written and
# full of hacks.

# When you run this script, you have to be in the directory with all the TIGER shapefiles. You
# also need to create a directory called output within the current directory.
# Change these variables according to the file names you have.
infile="../allegheny county buildings.osm"
ogr2poly="../ogr2poly.py"
osmconvert="../osmconvert64"

# If you've run this script before and you're going to run it again, try deleting all the poly
# files and .osm output files first:
# rm ./*.poly ./output/*.osm

# Create an OSM extract based on a large OSM file and a shape file containing the region to extract.
process_file() {
    i="$*"
    echo "$i"
    # Source for grep command:
    # https://unix.stackexchange.com/questions/234432/how-to-delete-the-last-column-of-a-file-in-linux
    base=$(echo $i |grep -Po '.*(?=\.+[^\.]+$)')
    # Get the ID from the filename. This is a terrible hack but
    # works for us.
    geoid=$(echo "$i" | cut -d '_' -f 4 | cut -d '.' -f 1)
    # Next we need to convert the .shp boundary into .poly format:
    "$ogr2poly" "$i"
    # This is the location where ogr2poly puts the output .poly file.
    polyfile="$base"_0.poly
    # Cut out the region with osmconvert.
    "$osmconvert" --complete-multipolygons $infile -B=$polyfile -o="./output/"$geoid".osm"
    return
}

IFS="
"

# Process the files in parallel, with a max of 4 tasks at once by default.
# This is easy because cutting the chunks out of the main file is an
# embarrasingly parallel task.

# The maximum number of concurrent tasks. Set this to the number of threads you CPU
# has. If it's too low, it will run slower. If it's too high, it will use more RAM
# and possibly run a litte slower.
maxjobs=4
for i in $(find ./ -maxdepth 1 | grep 'shp') ; do
    njobs=$(jobs | grep -i running | wc -l)
    while ( (( njobs >= $maxjobs )) ); do
        sleep 0.1
        njobs=$(jobs | grep -i running | wc -l)
    done
    process_file "$i" &
done

wait

exit
