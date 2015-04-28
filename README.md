# broccoli
Broccoli for TOS;DR (Terms of Service; Didn't Read) is a free extension available in the Chrome App Store.

Download link: https://chrome.google.com/webstore/detail/broccoli/fmbgfnapanennphegjjfjgdlopobepod

Review websites' terms of service and privacy policies, one point at a time, with the latest summaries from www.tosdr.org. Broccoli displays these summaries one point at a time, so that you can digest these agreements over time (there's also a list-view for a succinct overview).

Features:
- Nicely formatted, point-by-point descriptions (along with metadata).
- Option to review a service's points (Is this fair? yes or no) (and download/export or clear all of your reviews).
- A succinct list-view that provides a quick-look for all points of a website.
- If a point is updated by TOS;DR, Broccoli will return it to 'un-reviewed' status.
- Draws information from one of the best sources of summarized terms of service and privacy policies on the net.

------------------------------------------------------------------------

- written with coffeescript (www.coffeescript.org)
and the command 'coffee -o broccoli/package -cw broccoli/coffeescripts'
from the root directory

To just toy around with extension and not worry about minification
go to popup.html and uncomment the script popup.js and background.js lines
(and comment out the popup.min.js and background.min.js)
^^ then do the same in the manifest.json


- using uglify for minification (https://www.npmjs.com/package/uglify-js)

and the command 
uglifyjs popup.js --compress -o popup.min.js
uglifyjs background.js --compress -o background.min.js
and then manually deleting extra JS files before zipping package

Then you can load unpacked extension.