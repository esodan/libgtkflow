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
     * A Sink is a special Type of Dock that receives data from
     * A source in order to let it either 
     */
    public class Sink : Dock {
        /**
         * The Source that this Sink draws its data from
         */
        private weak Source? _source;
        public weak Source? source {
            get{
                return this._source;
            }
            default=null;
        }

        public Sink(GLib.Value initial) {
            base(initial);
        }

        public virtual void set_source(Source s) throws NodeError{
            this.unset_source();
            if (this.val.type() != s.val.type()) {
                throw new NodeError.INCOMPATIBLE_SOURCETYPE(
                    "Can't connect. Source has type %s while Sink has type %s".printf(
                        s.val.type().name(), this.val.type().name()
                    )
                );
            }
            this._source = s;
            if (!this._source.connected_to(this))
                this._source.add_sink(this);
            this.connected(s);
        }

        public virtual void unset_source() {
            if (this._source.connected_to(this))
                this._source.remove_sink(this);
            Source s = this._source;
            this._source = null;
            this.invalidate();
            this.disconnected(s);
        }

        /**
         * Checks if there is a source that supplies this sink with a value.
         * If yes, it returns that value. If not, returns the default value of
         * This Sink
         */
        public GLib.Value get_value() throws NodeError {
            if (this.source != null && this.valid) {
                return this.val;
            } else {
                throw new NodeError.NO_SOURCE("This sink has no source to drain data from");
            }
        }

        /**
         * Returns true if this Sink is connected to the given Source
         */
        public bool connected_to(Source s) {
            return this.source == s;
        }

        /**
         * Returns true if this sink is connected to a source
         */
        public override bool is_connected() {
            return this.source != null;
        }

        public override void invalidate () {
            this.valid = false;
            this.changed(this.initial);
        }

        public void change_value(GLib.Value v) throws NodeError {
            if (this.val.type() != v.type())
                throw new NodeError.INCOMPATIBLE_VALUE(
                    "Cannot feed a %s value into this %s Sink".printf(
                        v.type().name(),this.val.type().name())
                );
            this.val = v;
            this.valid = true;
            this.changed(v);
        }

        public virtual signal void changed(GLib.Value v) {
            this.val = v;
        }

        public override void update_layout(){
            string labelstring;
            if (this.node != null && this.node.show_types) {
                labelstring = "%s : <i>%s</i>".printf(
                    this.label,
                    this.typestring ?? this.determine_typestring()
                );
            } else {
                labelstring = label;
            }
            this.layout.set_markup(labelstring, -1);
            this.size_changed();
        }

        public void draw_sink(Cairo.Context cr, int offset_x, int offset_y) {
            Gtk.StyleContext sc = this.get_style_context();
            sc.save();
            if (this.is_connected())
                sc.set_state(Gtk.StateFlags.CHECKED);
            if (this.highlight)
                sc.set_state(sc.get_state() | Gtk.StateFlags.PRELIGHT);
            if (this.pressed)
                sc.set_state(sc.get_state() | Gtk.StateFlags.ACTIVE);
            sc.add_class(Gtk.STYLE_CLASS_RADIO);
            sc.render_option(cr, offset_x,offset_y,Dock.HEIGHT,Dock.HEIGHT);
            sc.restore();
            sc.save();
            sc.add_class(Gtk.STYLE_CLASS_BUTTON);
            Gdk.RGBA col = sc.get_color(Gtk.StateFlags.NORMAL);
            cr.set_source_rgba(col.red,col.green,col.blue,col.alpha);
            cr.move_to(offset_x+Dock.HEIGHT+Dock.SPACING_X, offset_y);
            Pango.cairo_show_layout(cr, this.layout);
            sc.restore();

            /*
            Important stateflags
            sc.set_state(Gtk.StateFlags.ACTIVE | Gtk.StateFlags.CHECKED | Gtk.StateFlags.PRELIGHT);
            */
        }
    }
}
