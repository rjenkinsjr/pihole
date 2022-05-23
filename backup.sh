#!/bin/bash
echo 'Extracting Pi-Hole config...'
mkdir temp
cd temp
pihole -a -t
TGZ=$(ls)
tar xzf $TGZ
rm -f $TGZ
echo 'Retrieving blocklists and merging with blacklist...'
for LINE in $(cat adlists.list); do
  echo "$LINE"
  curl -sSLk "$LINE" >> merged.txt
done
cat blacklist.txt >> merged.txt
echo 'Sanitizing blacklist and removing whitelist entries...'
# 1. Remove all comment lines.
# 2. Remove addresses at start of each line.
# 3. Trim all lines.
# 4. Remove all blank lines.
# 5. Remove all whitelisted lines.
# 6. Remove bad literal values.
# 7. Remove anything that doesn't have a dot in it.
# 8. Add 0.0.0.0 prefix needed for AdAway.
cat merged.txt | \
  grep -v '^#' | \
  awk '{sub(/^[^ \t]+[ \t]+/,"");}1' | \
  awk '{gsub(/ /,"");print}' | \
  grep -v '^$' | \
  grep -Fvxf whitelist.txt | \
  grep -Fvx \
    -e 'localhost' \
    -e 'localhost.localdomain' \
    -e 'local' \
    -e 'broadcasthost' \
    -e 'ip6-localhost' \
    -e 'ip6-loopback' \
    -e 'ip6-localnet' \
    -e 'ip6-mcastprefix' \
    -e 'ip6-allnodes' \
    -e 'ip6-allrouters' \
    -e 'ip6-allhosts' \
    -e '0.0.0.0' | \
  grep -E '[^.]*[.].+' | \
  sed -e 's/^/0.0.0.0 /' | \
  split -l 50000 -a 3 -d - blocklist
echo 'Cleaning up...'
rm -f ../blocklist*
mv blocklist* ..
cd ..
rm -rf temp
echo 'Committing to GitHub...'
git add blocklist
git commit -m "$(date)"
git push
echo 'Done.'
