/********************************************************************
# Copyright 2014 Daniel 'grindhold' Brendle
#
# This file is part of libgtkflow.
#
# libgtkflow is free software: you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later
# version.
#
# libgtkflow is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE. See the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with libgtkflow.
# If not, see http://www.gnu.org/licenses/.
*********************************************************************/

namespace GtkFlow {
    /**
     * This class represents an endpoint of a node. These endpoints can be
     * connected in order to let them exchange data. The data contained
     * in this endpoint is stored as GLib.Value. Only Docks that contain
     * data with the same VariantType can be interconnected.
     */
    public abstract class Dock : Gtk.Widget {
        public const int HEIGHT = 16;
        public const int SPACING_X = 5;
        public const int SPACING_Y = 3;

        protected Gtk.StyleContext style_context;
        protected Pango.Layout layout;

        protected string label = "";

        /**
         * Determines whether this dock is going to be drawn
         * with a mouse-over-halo
         */
        public bool highlight {get; set; default=false;}

        /**
         * Determines whether this dock is going to be drawn as pressed
         */
        public bool pressed {get; set; default=false;}

        /**
         * A reference to the node this Dock resides in
         */
        protected weak Node? node = null;

        /**
         * The value that is stored in this Dock
         */
        protected GLib.Value val;

        /**
         * Set the labelstring
         */
        public virtual void set_label (string label) {
            this.label = label;
            this.layout.set_text(label, -1);
            this.size_changed();
        }

        /**
         * Returs true if this and the supplied dock have
         * same type
         */
        public bool has_same_type(Dock other) {
            return this.val.type_name() == other.val.type_name();
        }

        /**
         * Returns the current labelstring
         */
        public virtual string get_label() {
            return this.label;
        }

        /**
         * Initialize this with a value
         */
        protected Dock(GLib.Value initial) {
            base();
            this.val = initial;
            this.layout = this.create_pango_layout(this.label);
        }

        /**
         * This signal is being triggered, when there is a connection being established
         * from or to this Dock.
         */
        public signal void connected(Dock d);

        /**
         * This signal is being triggered, when there is a connection being established
         * from or to this Dock.
         */
        public signal void disconnected(Dock d);

        /**
         * Triggers when something leads to this dock chaging in size
         */
        public signal void size_changed();

        public abstract bool is_connected();

        /**
         * Set the reference to a node on this dock
         */
        public void set_node(Node? n) {
            this.node = n;
        }

        /**
         * Get the node that this dock resides in
         */
        public unowned Node? get_node() {
            return this.node;
        }

        /**
         * Get the minimum width for this dock
         */
        public virtual int get_min_height() {
            int width, height;
            this.layout.get_pixel_size(out width, out height);
            return (int)(Math.fmax(height, Dock.HEIGHT))+Dock.SPACING_Y;
        }

        /**
         * Get the minimum height for this dock
         */
        public virtual int get_min_width() {
            int width, height;
            this.layout.get_pixel_size(out width, out height);
            return (int)(width + Dock.HEIGHT + Dock.SPACING_X);
        }
    }
}
