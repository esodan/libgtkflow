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
     * The Source is a special Type of Dock that provides data.
     * A Source can provide a multitude of Sinks with data.
     */
    public class Source : Dock {
        private List<Sink> sinks = new List<Sink>();

        public Source(GLib.Value initial) {
            base(initial);
        }

        public void set_value(GLib.Value v) throws NodeError {
            if (this.val.type() != v.type())
                throw new NodeError.INCOMPATIBLE_VALUE(
                    "Cannot set a %s value to this %s Source".printf(
                        v.type().name(),this.val.type().name())
                );
            this.val = v;
            foreach (Sink s in this.sinks)
                s.change_value(v);
        }

        public virtual void add_sink(Sink s) throws NodeError {
            if (this.val.type() != s.val.type()) {
                throw new NodeError.INCOMPATIBLE_SINKTYPE(
                    "Can't connect. Sink has type %s while Source has type %s".printf(
                        s.val.type().name(), this.val.type().name()
                    )
                );
            }
            if (this.sinks.index(s) == -1)
                this.sinks.append(s);
            if (!s.connected_to(this))
                s.set_source(this);
            s.change_value(this.val);
        }

        public virtual void remove_sink(Sink s){
            if (this.sinks.index(s) != -1)
                this.sinks.remove(s);
            if (s.connected_to(this))
                s.unset_source();
            try {
                s.change_value(0);
            } catch {
                warning("Could not reset the sink");
            }
            this.disconnected(s);
        }

        public virtual void remove_sinks() {
            foreach (Sink s in this.sinks)
                this.remove_sink(s);
        }

        /**
         * Returns true if this Source is connected to the given Sink
         */
        public bool connected_to(Sink s) {
            return this.sinks.index(s) != -1;
        }

        /**
         * Returns true if this Source is connected to one or more Sinks
         */
        public override bool is_connected() {
            return this.sinks.length() > 0;
        }

        /**
         * Returns the sinks that this source is connected to
         */
        public unowned List<Sink> get_sinks() {
            return this.sinks;
        }

        /**
         * Draw this source onto a cairo context
         */
        public void draw_source(Cairo.Context cr, int offset_x, int offset_y, int width) {
            Gtk.StyleContext sc = this.get_style_context();
            sc.save();
            if (this.is_connected())
                sc.set_state(Gtk.StateFlags.CHECKED);
            if (this.highlight)
                sc.set_state(sc.get_state() | Gtk.StateFlags.PRELIGHT);
            if (this.pressed)
                sc.set_state(sc.get_state() | Gtk.StateFlags.ACTIVE);
            sc.add_class(Gtk.STYLE_CLASS_RADIO);
            sc.render_option(cr, offset_x+width-Dock.HEIGHT,offset_y,Dock.HEIGHT,Dock.HEIGHT);
            sc.restore();
            sc.save();
            sc.add_class(Gtk.STYLE_CLASS_BUTTON);
            Gdk.RGBA col = sc.get_color(Gtk.StateFlags.NORMAL);
            cr.set_source_rgba(col.red,col.green,col.blue,col.alpha);
            cr.move_to(offset_x + width - this.get_min_width(), offset_y);
            Pango.cairo_show_layout(cr, this.layout);
            sc.restore();
        }
    }
}
