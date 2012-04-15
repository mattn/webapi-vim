for item in webapi#feed#parseURL('http://rss.slashdot.org/Slashdot/slashdot')
  echo item.link
  echo "  " item.title
endfor
