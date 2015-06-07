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
        NO_SOURCE,
        /**
         * Throw when there is no Dock available on this position
         */
        NO_DOCK_ON_POSITION,
        /**
         * Throw when the user tries to add a dock to a node
         * That already contains a dock
         */
        ALREADY_HAS_DOCK,
        /**
         * Throw when the dock that the user tries to add already
         * belongs to another node
         */
        DOCK_ALREADY_BOUND_TO_NODE,
        /**
         * Throw when the user tries to remove a dock from a node
         * that hasn't yet been added to the node
         */
        NO_SUCH_DOCK
    }


    /**
     * Represents an element that can generate, process or receive data
     * This is done by adding Sources and Sinks to it. The inner logic of
     * The node can be represented towards the user as arbitrary Gtk widget.
     */
    public class Node : Gtk.Bin {
        // Determines the space between the title and the first dock (y-axis)
        // as well as the space between the title and the close-button if any (x-axis)
        private const int TITLE_SPACING = 15;
        private const int DELETE_BTN_SIZE = 16;
        private const int RESIZE_HANDLE_SIZE = 10;
        private List<Source> sources = new List<Source>();
        private List<Sink> sinks = new List<Sink>();

        private NodeView? node_view = null;

        private Gtk.Allocation node_allocation;

        private string title = "";
        private Pango.Layout layout;

        public bool show_types {get; set; default=false;}

        public Node () {
            this.node_allocation = {0,0,0,0};
            this.set_border_width(RESIZE_HANDLE_SIZE);
            this.recalculate_size();
        }

        public void set_title(string title) {
            this.title = title;
            this.layout = this.create_pango_layout("");
            this.layout.set_markup("<b>%s</b>".printf(this.title),-1);
            this.recalculate_size();
            this.node_view.queue_draw();
        }

        public void set_node_allocation(Gtk.Allocation alloc) {
            if (alloc.width < (int)this.get_min_width())
                alloc.width = (int)this.get_min_width();
            if (alloc.height < (int)this.get_min_height())
                alloc.height = (int)this.get_min_height();
            this.node_allocation = alloc;
        }

        public void set_position(int x, int y) {
            this.node_allocation.x = x;
            this.node_allocation.y = y;
            this.node_view.queue_draw();
        }

        public void get_node_allocation(out Gtk.Allocation alloc) {
            alloc = Gtk.Allocation();
            alloc.x = this.node_allocation.x;
            alloc.y = this.node_allocation.y;
            alloc.width = this.node_allocation.width;
            alloc.height = this.node_allocation.height;
        }

        public override void add(Gtk.Widget w) {
            w.set_parent(this);
            base.add(w);
        }

        public override void remove(Gtk.Widget w) {
            w.unparent();
            base.remove(w);
        }

        public void add_source(Source s) throws NodeError {
            if (s.get_node() != null)
                throw new NodeError.DOCK_ALREADY_BOUND_TO_NODE("This Source is already bound");
            if (this.sources.index(s) != -1)
                throw new NodeError.ALREADY_HAS_DOCK("This node already has this source");
            sources.append(s);
            s.set_node(this);
            s.update_layout();
            this.recalculate_size();
            s.size_changed.connect(this.recalculate_size);
        }

        public void add_sink(Sink s) throws NodeError {
            if (s.get_node() != null)
                throw new NodeError.DOCK_ALREADY_BOUND_TO_NODE("This Sink is already bound" );
            if (this.sinks.index(s) != -1)
                throw new NodeError.ALREADY_HAS_DOCK("This node already has this sink");
            sinks.append(s);
            s.set_node(this);
            s.update_layout();
            this.recalculate_size();
            s.size_changed.connect(this.recalculate_size);
        }

        public void remove_source(Source s) throws NodeError {
            if (this.sources.index(s) == -1)
                throw new NodeError.NO_SUCH_DOCK("This node doesn't have this source");
            sources.remove(s);
            s.set_node(null);
            this.recalculate_size();
            s.size_changed.disconnect(this.recalculate_size);
        }

        public void remove_sink(Sink s) throws NodeError {
            if (this.sinks.index(s) == -1)
                throw new NodeError.NO_SUCH_DOCK("This node doesn't have this sink");
            sinks.remove(s);
            s.set_node(null);
            this.recalculate_size();
            s.size_changed.disconnect(this.recalculate_size);
        }

        public bool has_sink(Sink s) {
            return this.sinks.index(s) != -1;
        }

        public bool has_source(Source s) {
            return this.sources.index(s) != -1;
        }

        public bool has_dock(Dock d) {
            if (d is Source)
                return this.has_source(d as Source);
            else
                return this.has_sink(d as Sink);
        }

        /**
         * Returns the sources of this node
         */
        public unowned List<Source> get_sources() {
            return this.sources;
        }

        public new void set_border_width(uint border_width) {
            if (border_width < RESIZE_HANDLE_SIZE) {
                warning("Cannot set border width smaller than %d", RESIZE_HANDLE_SIZE);
                return;
            }
            base.set_border_width(border_width);
            this.recalculate_size();
            this.node_view.queue_draw();
        }

        public void set_node_view(NodeView? n) {
            this.node_view = n;
        }

        /**
         * This method checks whether a connection from the given from-Node
         * to this Node would lead to a recursion
         */
        public bool is_recursive(Node from, bool initial=true) {
            if (!initial && this == from)
                return true;
            foreach (Source source in this.get_sources()) {
                foreach (Sink sink in source.get_sinks()) {
                    if (sink.get_node().is_recursive(from, false))
                        return true;
                }
            }
            return false;
        }

        /**
         * Returns the position of the given dock.
         * This is obviously bullshit. Docks should be able to know
         * their own position
         */
        /*
         * TODO: find better solution
         */
        public Gdk.Point get_dock_position(Dock d) throws NodeError {
            int i = 0;
            Gdk.Point p = {0,0};

            if (this.node_view != null) {
                p.x -= (int)this.node_view.hadjustment.get_value();
                p.y -= (int)this.node_view.vadjustment.get_value();
            }

            uint title_offset = this.get_title_line_height();

            foreach (Dock s in this.sinks) {
                if (s == d) {
                    p.x += (int)(this.node_allocation.x + this.border_width + Dock.HEIGHT/2);
                    p.y += (int)(this.node_allocation.y + this.border_width + title_offset
                              + Dock.HEIGHT/2 + i * s.get_min_height());
                    return p;
                }
                i++;
            }
            foreach (Dock s in this.sources) {
                if (s == d) {
                    p.x += (int)(this.node_allocation.x - this.border_width
                              + this.node_allocation.width - Dock.HEIGHT/2);
                    p.y += (int)(this.node_allocation.y + this.border_width + title_offset
                              + Dock.HEIGHT/2 + i * s.get_min_height());
                    return p;
                }
                i++;
            }
            throw new NodeError.NO_SUCH_DOCK("There is no such dock in this node");
        }

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
            mw += this.get_title_line_height();
            foreach (Dock d in this.sinks) {
                mw += d.get_min_height();
            }
            foreach (Dock d in this.sources) {
                mw += d.get_min_height();
            }
            Gtk.Widget child = this.get_child();
            if (child != null) {
                int child_height, _;
                child.get_preferred_height(out child_height, out _);
                mw += child_height;
            }
            return mw;
        }

        /**
         * Returns the minimum width this node has to have
         */
        public uint get_min_width() {
            uint mw = 0;
            int t = 0;
            if (this.title != "") {
                int width, height;
                this.layout.get_pixel_size(out width, out height);
                mw = width + TITLE_SPACING + DELETE_BTN_SIZE;
            }
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
                int child_width, _;
                child.get_preferred_width(out child_width, out _);
                if (child_width > mw)
                    mw = child_width;
            }
            return mw + this.border_width*2;
        }

        private uint get_title_line_height() {
            int width, height;
            if (this.title == "") {
                 width = height = 0;
            } else {
                this.layout.get_pixel_size(out width, out height);
            }
            return (uint)Math.fmax(height, DELETE_BTN_SIZE) + Node.TITLE_SPACING;
        }

        /**
         * Determines whether the mousepointer is hovering over a dock on this node
         */
        public Dock? get_dock_on_position(Gdk.Point p) {
            int x = p.x;
            int y = p.y;

            stdout.printf("maus %d %d\n",x,y);

            double scroll_x = this.node_view != null ? this.node_view.hadjustment.value : 0;
            double scroll_y = this.node_view != null ? this.node_view.vadjustment.value : 0;

            int i = 0;

            int dock_x, dock_y;
            uint title_offset;
            title_offset = this.get_title_line_height();
            foreach (Dock s in this.sinks) {
                dock_x = this.node_allocation.x + (int)this.border_width - (int)scroll_x;
                dock_y = this.node_allocation.y + (int)this.border_width + (int)title_offset
                         + i * s.get_min_height() - (int)scroll_y;
                stdout.printf("dock %d %d\n", dock_x, dock_y);
                if (x > dock_x && x < dock_x + Dock.HEIGHT
                        && y > dock_y && y < dock_y + Dock.HEIGHT )
                    return s;
                i++;
            }
            foreach (Dock s in this.sources) {
                dock_x = this.node_allocation.x + this.node_allocation.width
                         - (int)this.border_width - Dock.HEIGHT - (int)scroll_x;
                dock_y = this.node_allocation.y + (int)this.border_width + (int)title_offset
                         + i * s.get_min_height() - (int)scroll_y;
                stdout.printf("dock %d %d\n", dock_x, dock_y);
                if (x > dock_x && x < dock_x + Dock.HEIGHT
                        && y > dock_y && y < dock_y + Dock.HEIGHT )
                    return s;
                i++;
            }
            return null;
        }

        /**
         * Returns true if the point is on the close-button of the node
         */
        public bool is_on_closebutton(Gdk.Point p) {
            int x = p.x;
            int y = p.y;

            double scroll_x = this.node_view != null ? this.node_view.hadjustment.value : 0;
            double scroll_y = this.node_view != null ? this.node_view.vadjustment.value : 0;

            Gtk.Allocation alloc;
            this.get_node_allocation(out alloc);
            int x_left = alloc.x + alloc.width - DELETE_BTN_SIZE
                                 - (int)border_width - (int)scroll_x;
            int x_right = x_left + DELETE_BTN_SIZE;
            int y_top = alloc.y + (int)border_width - (int)scroll_y;
            int y_bot = y_top + DELETE_BTN_SIZE;
            return x > x_left && x < x_right && y > y_top && y < y_bot;
        }

        /**
         * Returns true if the point is in the resize-drag area
         */
        public bool is_on_resize_handle(Gdk.Point p) {
            int x = p.x;
            int y = p.y;

            double scroll_x = this.node_view != null ? this.node_view.hadjustment.value : 0;
            double scroll_y = this.node_view != null ? this.node_view.vadjustment.value : 0;

            Gtk.Allocation alloc;
            this.get_node_allocation(out alloc);
            int x_left = alloc.x + alloc.width - RESIZE_HANDLE_SIZE - (int)scroll_x;
            int x_right = alloc.x + alloc.width;
            int y_top = alloc.y + alloc.height - RESIZE_HANDLE_SIZE - (int)scroll_y;
            int y_bot = alloc.y + alloc.height;
            return x > x_left && x < x_right && y > y_top && y < y_bot;
        }

        /**
         * Disconnect all connections from and to this node
         */
        public void disconnect_all() {
            foreach (Source s in this.sources) {
                s.remove_sinks();
            }
            foreach (Sink s in this.sinks) {
                s.unset_source();
            }
        }


        /**
         * Draw this node on the given cairo context
         */
        public void draw_node(Cairo.Context cr) {
            Gtk.Allocation alloc;
            this.get_node_allocation(out alloc);

            if (this.node_view != null) {
                alloc.x -= (int)this.node_view.hadjustment.get_value();
                alloc.y -= (int)this.node_view.vadjustment.get_value();
            }

            Gtk.StyleContext sc = this.get_style_context();
            sc.save();
            sc.add_class(Gtk.STYLE_CLASS_BUTTON);
            sc.render_background(cr, alloc.x, alloc.y, alloc.width, alloc.height);
            sc.render_frame(cr, alloc.x, alloc.y, alloc.width, alloc.height);
            sc.restore();

            int y_offset = 0;

            if (this.title != "") {
                sc.save();
                cr.save();
                sc.add_class(Gtk.STYLE_CLASS_BUTTON);
                Gdk.RGBA col = sc.get_color(Gtk.StateFlags.NORMAL);
                cr.set_source_rgba(col.red,col.green,col.blue,col.alpha);
                cr.move_to(alloc.x + this.border_width,
                           alloc.y + (int) this.border_width + y_offset);
                Pango.cairo_show_layout(cr, this.layout);
                cr.restore();
                sc.restore();
            }
            if (this.node_view != null && this.node_view.editable) {
                Gtk.IconTheme it = Gtk.IconTheme.get_default();
                try {
                    cr.save();
                    Gdk.Pixbuf icon_pix = it.load_icon("edit-delete", DELETE_BTN_SIZE, 0);
                    Gdk.cairo_set_source_pixbuf(
                        cr, icon_pix,
                        alloc.x+alloc.width-DELETE_BTN_SIZE-border_width,
                        alloc.y+border_width
                    );
                    cr.paint();
                } catch (GLib.Error e) {
                    warning("Could not load close-node-icon 'edit-delete'");
                } finally {
                    cr.restore();
                }
            }
            y_offset += (int)this.get_title_line_height();

            foreach (Sink s in this.sinks) {
                s.draw_sink(cr, alloc.x + (int)this.border_width,
                                alloc.y+y_offset + (int) this.border_width);
                y_offset += s.get_min_height();
            }
            foreach (Source s in this.sources) {
                s.draw_source(cr, alloc.x-(int)this.border_width,
                                  alloc.y+y_offset + (int) this.border_width, alloc.width);
                y_offset += s.get_min_height();
            }

            Gtk.Widget child = this.get_child();
            if (child != null) {
                Gtk.Allocation child_alloc = {0,0,0,0};
                child_alloc.x = alloc.x + (int)border_width;
                child_alloc.y = alloc.y + (int)border_width + y_offset;
                child_alloc.width = alloc.width - 2 * (int)border_width;
                child_alloc.height = alloc.height - 2 * (int)border_width - y_offset;
                child.size_allocate(child_alloc);

                this.propagate_draw(child, cr);
            }
            // Draw resize handle
            sc.save();
            cr.save();
            cr.set_source_rgba(0.5,0.5,0.5,0.5);
            cr.move_to(alloc.x + alloc.width,
                       alloc.y + alloc.height);
            cr.line_to(alloc.x + alloc.width - RESIZE_HANDLE_SIZE,
                       alloc.y + alloc.height);
            cr.line_to(alloc.x + alloc.width,
                       alloc.y + alloc.height - RESIZE_HANDLE_SIZE);
            cr.fill();
            cr.stroke();
            cr.restore();
            sc.restore();
        }
    }
}
