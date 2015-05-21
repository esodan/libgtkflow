GtkFlow
=======

Here you see libgtkflow, a universal library for drawing flowgraphs with
Gtk+ 3.

![GtkFlow](https://i.imgur.com/BWcXGkV.png)

Flowgraphs are a possibility to let your user model the flow of data through
several stations.

Motivation
----------

I love Flowgraphs in other programs and i want to have them in my favourite
UI-toolkit Gtk. I saw some programs that implemented similar functionality
but they all don't look and feel very Gtk-esque/GNOMEy.

Possible Usages
---------------

Specific:

  * Writing a UI for [GStreamer](http://gstreamer.org)
  * Writing a UI for [Beehive](https://github.com/muesli/beehive)
  * Replacement for the UI in [Gnuradio](http://gnuradio.org)

Unspecific:

  * Video Compositing (maybe [PiTiVi](http://www.pitivi.org))

  * And whatever you can think up.

Stability
-------------

Consider the API unstable by now.
You will encounter bugs.

Building
--------

Make sure you get the following Dependencies:

  * libgee-0.8-dev
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

libgtkflow supports GObject-Introspection so you can program against it in various
popular languages including but not limited to: Python, Perl, Lua, JS, PHP.
I compiled some examples on how to program against the library in Python in the examples-folder.

Feel free to add examples for your favourite language.

Note: If you installed the library in /usr/local, you have to do export the following
environment variables in order for the examples to work:

```
$ export LD_LIBRARY_PATH=/usr/local/lib 
$ export GI_TYPELIB_PATH=/usr/local/lib/girepository-1.0/
```