GtkFlow
=======

Here you see libgtkflow, a universal library for drawing flow graphs with
Gtk+ 3.

![GtkFlowEvopop](http://i.imgur.com/s7qbTPT.png)

This is a screenshot of libgtkflow rendered with the evopop Gtk3 theme

![GtkFlow](https://i.imgur.com/BWcXGkV.png)

This here is the included advanced calculator demo application ↑

Flow graphs are a possibility to let your user model flows of data from, through
and into several stations.

Motivation
----------

I love Flowgraphs in other programs and i want to have them in my favourite
UI-toolkit Gtk. I ran into some programs which implemented similar functionality
but they all didn't feel or even lokk very Gtk-like/GNOMEy.

Possible Usages
---------------

Specific:

  * Writing a UI for [GStreamer](http://gstreamer.org)
  * Writing a UI for [Beehive](https://github.com/muesli/beehive)
  * Replacement for the UI in [Gnuradio](http://gnuradio.org)
  * Matching monitors / inputs / outputs in [Pavucontrol](http://freedesktop.org/software/pulseaudio/pavucontrol/)

Unspecific:

  * Video Compositing (maybe [PiTiVi](http://www.pitivi.org))
  * Visualizing dependencies of objects (e.g. debian packages in apt)

  * … and whatever you can think up.

Stability
-------------

Consider the API unstable for now.
You will encounter bugs.

Building
--------

Make sure you get the following Dependencies:

  * libgtk-3-dev
  * gobject-introspection
  * cmake
  * vala

Then do the following:

```
$ cmake .
$ sudo make install
```

Examples
--------

libgtkflow supports GObject-Introspection which means you can consume it in various
popular languages including but not limited to: Python, Perl, Lua, JS, PHP.
I compiled some examples on how to program against the library in Python in the examples-folder.

Feel free to add examples for your favorite language.

Note: If you installed the library in /usr/local, you have to export the following
environment variables for the examples to work:

```
$ export LD_LIBRARY_PATH=/usr/local/lib 
$ export GI_TYPELIB_PATH=/usr/local/lib/girepository-1.0/
```
