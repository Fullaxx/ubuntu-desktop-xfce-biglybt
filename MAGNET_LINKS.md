# Configuring Magnet Links

Firefox in the container's desktop can send the magnet links you click to BiglyBT. \
Firefox is in the image: Applications > Ubuntu Desktop > Network > Browsers > Firefox.

## Firefox
* Open Firefox, type `about:config` in the address bar and press Enter
* If Firefox shows "Proceed with Caution", click "Accept the Risk and Continue"
* Type `network.protocol-handler.expose.magnet` in the search box
* Select Boolean
* Click the + button to add it (it starts as true)
* Click the toggle button to set it to false
* Click any magnet link. Firefox asks whether to allow the site to open the magnet link: click "Choose Application"
* In the Choose Application window, click "Choose…" and select `/opt/biglybt/biglybt`
* Check "Always use this application to open magnet links" and click "Open Link"

Magnet links now open in BiglyBT. Firefox still asks before a site opens one: click "Open Link"
(check "Always allow" first, and it stops asking for that site).
