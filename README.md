# gentoo-overlay-da707-lua
Gentoo Portage Overlay for Lua Packages like Prosody IM

## Installation Layman
Add to the /etc/layman/layman.cfg the URI to the overlay.xml in the overlays section: 

<pre>
overlays :
    https://raw.githubusercontent.com/DevelAngel707/gentoo-overlay-da707-lua/master/overlay.xml
</pre>

Then, synchronize all remotes and add the overlay da707-lua. After that, you can update your eix database.
<pre>
layman -S
layman -a da707-lua
eix-update
</pre>
