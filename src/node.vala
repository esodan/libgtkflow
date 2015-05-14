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

/**
 * Flowgraphs for Gtk
 */
namespace GtkFlow {
    public errordomain NodeError {
        /**
         * Throw when the user tries to connect a sink to a source that
         * Delivers a different type
         */
        INCOMPATIBLE_SOURCETYPE,
        /**
         * Throw when the user tries to connect a source to a sink that
         * Delivers a different type
         */
        INCOMPATIBLE_SINKTYPE,
        /**
         * Throw when a user tries to assign a value with a wrong type
         * to a sink
         */
        INCOMPATIBLE_VALUE,
        /**
         * Throw then the user tries to get a value from a sink that
         * is currently not connected to any source
         */
        NO_SOURCE
    }


    /**
     * Represents an element that can generate, process or receive data
     * This is done by adding Sources and Sinks to it. The inner logic of
     * The node can be represented towards the user as arbitrary Gtk widget.
     */
    public class Node : Gtk.Bin {
        private Gee.ArrayList<Source> sources = new Gee.ArrayList<Source>();
        private Gee.ArrayList<Sink> sinks = new Gee.ArrayList<Sink>();

        private Gtk.Allocation node_allocation;

        public Node () {
            this.node_allocation = {0,0,00,00};
            this.recalculate_size();
        }

        public void set_node_allocation(Gtk.Allocation alloc) {
            this.node_allocation = alloc;
        }

        public void get_node_allocation(out Gtk.Allocation alloc) {
            alloc.x = this.node_allocation.x;
            alloc.y = this.node_allocation.y;
            alloc.width = this.node_allocation.width;
            alloc.height = this.node_allocation.height;
        }

        public void add_source(Source s) {
            if (!this.sources.contains(s)) {
                sources.add(s);
                this.recalculate_size();
                s.size_changed.connect(this.recalculate_size);
            }
        }

        public void add_sink(Sink s) {
            if (!this.sinks.contains(s)) {
                sinks.add(s);
                this.recalculate_size();
                s.size_changed.connect(this.recalculate_size);
            }
        }

        public void remove_source(Source s) {
            if (this.sources.contains(s)) {
                sources.remove(s);
                this.recalculate_size();
                s.size_changed.disconnect(this.recalculate_size);
            }
        }

        public void remove_sink(Sink s) {
            if (this.sinks.contains(s)) {
                sinks.remove(s);
                this.recalculate_size();
                s.size_changed.disconnect(this.recalculate_size);
            }
        }

        /*public bool motion_notify_event(Gdk.EventMotion e) {
            // Determine x/y coords relative to this node's zero coordinates
            Gtk.Allocation alloc;
            this.get_node_allocation(out alloc);
            int local_x = (int)e.x - alloc.x;
            int local_y = (int)e.y - alloc.y;
            return true;
        }*/

        /**
         * Checks if the node needs to be resized in order to fill the minimum
         * size requirements
         */
        public void recalculate_size() {
            Gtk.Allocation alloc;
            this.get_node_allocation(out alloc);
            uint mw = this.get_min_width();
            uint mh = this.get_min_height();
            if (mw > alloc.width)
                alloc.width = (int)mw;
            if (mh > alloc.height)
                alloc.height = (int)mh;
            this.set_node_allocation(alloc);
        }

        /**
         * Returns the minimum height this node has to have
         */
        public uint get_min_height() {
            uint mw = this.border_width*2;
            foreach (Dock d in this.sinks) {
                mw += d.get_min_height();
            }
            foreach (Dock d in this.sources) {
                mw += d.get_min_height();
            }
            Gtk.Widget child = this.get_child();
            if (child != null) {
                Gtk.Allocation alloc;
                child.get_allocation(out alloc);
                mw += alloc.height;
            }
            stdout.printf("min_height: %u\n", mw);
            return mw;
        }

        /**
         * Returns the minimum width this node has to have
         */
        public uint get_min_width() {
            uint mw = 0;
            int t = 0;
            foreach (Dock d in this.sinks) {
                t = d.get_min_width();
                if (t > mw)
                    mw = t;
            }
            foreach (Dock d in this.sources) {
                t = d.get_min_width();
                if (t > mw)
                    mw = t;
            }
            Gtk.Widget child = this.get_child();
            if (child != null) {
                Gtk.Allocation alloc;
                child.get_allocation(out alloc);
                if (alloc.width > mw)
                    mw = alloc.width;
            }
            stdout.printf("min_width: %u\n", mw);
            return mw + this.border_width*2;
        }

        /**
         * Determines whether the mousepointer is hovering over a dock on this node
         */
        public Dock? get_dock_on_position(Gdk.Point p) {
            int x = p.x;
            int y = p.y;

            int i = 0;

            int dock_x, dock_y;
            foreach (Dock s in this.sinks) {
                dock_x = (int)(this.node_allocation.x + this.border_width);
                dock_y = (int)(this.node_allocation.y + this.border_width 
                         + i * s.get_min_height());
                if (x > dock_x && x < dock_x + Dock.HEIGHT
                        && y > dock_y && y < dock_y + Dock.HEIGHT )
                    return s;
                i++;
            }
            foreach (Dock s in this.sources) {
                dock_x = (int)(this.node_allocation.x + this.node_allocation.width 
                         - this.border_width - Dock.HEIGHT);
                dock_y = (int)(this.node_allocation.y + this.border_width 
                         + i * s.get_min_height());
                if (x > dock_x && x < dock_x + Dock.HEIGHT
                        && y > dock_y && y < dock_y + Dock.HEIGHT )
                    return s;
                i++;
            }
            return null;
        }

        /**
         * Draw this node on the given cairo context
         * TODO: implement
         */
        public void draw_node(Cairo.Context cr) {
            Gtk.Allocation alloc;
            this.get_node_allocation(out alloc);

            Gtk.StyleContext sc = this.get_style_context();
            sc.save();
            sc.add_class(Gtk.STYLE_CLASS_BUTTON);
            sc.render_background(cr, alloc.x, alloc.y, alloc.width, alloc.height);
            sc.render_frame(cr, alloc.x, alloc.y, alloc.width, alloc.height);
            sc.restore();

            int y_offset = 0;
            foreach (Sink s in this.sinks) {
                s.draw_sink(cr, alloc.x, alloc.y+y_offset);
                y_offset += s.get_min_height();
            }
            foreach (Source s in this.sources) {
                s.draw_source(cr, alloc.x, alloc.y+y_offset, alloc.width);
                y_offset += s.get_min_height();
            }


            Gtk.Widget child = this.get_child();
            if (child != null)
                this.propagate_draw((Gtk.Widget)this.get_child(), cr);
        }
    }
}
