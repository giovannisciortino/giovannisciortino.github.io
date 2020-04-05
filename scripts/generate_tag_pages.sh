#!/bin/bash
EXTRACT_TAGS_FROM_POSTS=$(grep --no-filename tags _posts/*|cut -d"[" -f2|cut -d"]" -f1| tr ',' '\n'|sed 's/^ *//g'|sort|uniq)
for TAG in $EXTRACT_TAGS_FROM_POSTS ; do
cat > tag/${TAG}.md << EOL
---
title:  ""
tag: ${TAG}
---
{% include collecttags.html %}
<div class="post">
<h2>Posts with tag: {{ page.tag }}</h2>
<ul>
{% for post in site.tags[page.tag] %}
  <li><a href="{{ post.url }}">{{ post.title }}</a> ({{ post.date | date_to_string }})<br>
    {{ post.description }}
  </li>
{% endfor %}
</ul>
</div>
<hr>
EOL
done
