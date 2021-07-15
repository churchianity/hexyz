
# add -mac, -windows, -linux, or -html if you only want one target
rm -r build/*
amulet export -r -d build/ -a .
amulet export -r -d build/ -a -html .
