let loc = 'Osaka'
let dom = webapi#xml#parseURL(printf('http://www.google.com/ig/api?weather=%s', webapi#http#encodeURIComponent(loc)))
echo loc.'''s current weather is '.dom.find('current_conditions').childNode('condition').attr['data']
