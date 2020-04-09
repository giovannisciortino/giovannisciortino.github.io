#!/bin/bash
EXTRACT_TAGS_FROM_POSTS=$(grep --no-filename tags _posts/*|cut -d"[" -f2|cut -d"]" -f1| tr ',' '\n'|sed 's/^ *//g'|sort|uniq)
TAGS_CHILDREN=""

for TAG in $EXTRACT_TAGS_FROM_POSTS ; do
  TAGS_CHILDREN="${TAGS_CHILDREN}      - title: $TAG\n"
  TAGS_CHILDREN="${TAGS_CHILDREN}        url: /tag/$TAG/\n"
done

cat > _data/navigation.yml << EOF
main:
  - title: "About me"
    url: /about/

sidebar:
#  - title: "ARCHIVES"
#    children:
#      - title: March 2016
#        url: /child-1-page-url/
#      - title: February 2016
#        url: /child-1-page-url/
  - title: "TAGS"
    children:
$(echo -e "$TAGS_CHILDREN")
EOF
