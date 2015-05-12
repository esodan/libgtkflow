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
     * This class represents an endpoint of a node. These endpoints can be
     * connected in order to let them exchange data. The data contained
     * in this endpoint is stored as GLib.Value. Only Docks that contain
     * data with the same VariantType can be interconnected.
     */
    public abstract class Dock : Gtk.Widget {
        public const int HEIGHT = 15;
        public const int SPACING_X = 5;
        public const int SPACING_Y = 3;

        private int x = 0;
        private int y = 0;

        protected Gtk.StyleContext style_context;
        protected Pango.Layout layout;

        protected string label = "";

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
         * Triggers when something leads to this dock chaging in size
         */
        public signal void size_changed();

        public abstract bool is_connected();

        /**
         * Get the minimum width for this dock
         */
        public virtual int get_min_height() {
            stdout.printf(this.label+"\n");
            int width, height;
            this.layout.get_pixel_size(out width, out height);
            return (int)(Math.fmax(height, Dock.HEIGHT))+Dock.SPACING_Y;
        }

        /**
         * Get the minimum height for this dock
         */
        public virtual int get_min_width() {
            stdout.printf(this.label+"\n");
            int width, height;
            this.layout.get_pixel_size(out width, out height);
            return (int)(width + Dock.HEIGHT + Dock.SPACING_X);
        }
    }

    /**
     * The Source is a special Type of Dock that provides data.
     * A Source can provide a multitude of Sinks with data.
     */
    public class Source : Dock {
        private Gee.ArrayList<Sink> sinks = new Gee.ArrayList<Sink>();

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
            if (!this.sinks.contains(s))
                this.sinks.add(s);
            if (!s.connected_to(this))
                s.set_source(this);
            s.change_value(this.val);
        }

        /**
         * Returns true if this Source is connected to the given Sink
         */
        public bool connected_to(Sink s) {
            return this.sinks.contains(s);
        }

        /**
         * Returns true if this Source is connected to one or more Sinks
         */
        public override bool is_connected() {
            return this.sinks.size > 0;
        }

        /**
         * Draw this source onto a cairo context
         */
        public void draw_source(Cairo.Context cr, int offset_x, int offset_y, int width) {
            Gtk.StyleContext sc = this.get_style_context();
            sc.save();
            if (this.is_connected())
                sc.set_state(Gtk.StateFlags.CHECKED);
            sc.add_class(Gtk.STYLE_CLASS_RADIO);
            sc.render_option(cr, offset_x+width-Dock.HEIGHT,offset_y,Dock.HEIGHT,Dock.HEIGHT);
            sc.restore();
            sc.save();
            sc.add_class(Gtk.STYLE_CLASS_BUTTON);
            Gdk.RGBA col = sc.get_color(Gtk.StateFlags.NORMAL);
            stdout.printf("%d %d %d\n", (int)col.red, (int)col.green, (int)col.blue);
            cr.set_source_rgba(col.red,col.green,col.blue,col.alpha);
            cr.move_to(offset_x + width - this.get_min_width() - Dock.SPACING_X, offset_y);
            Pango.cairo_show_layout(cr, this.layout);
            sc.restore();
        }
    }

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

        /**
         * Checks if there is a source that supplies this sink with a value.
         * If yes, it returns that value. If not, returns the default value of
         * This Sink
         */
        public GLib.Value get_value() throws NodeError {
            if (this.source != null) {
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

        public void change_value(GLib.Value v) {
            this.val = v;
            this.changed(v);
        }

        public virtual signal void changed(GLib.Value v) {
            this.val = v;
        }

        public void draw_sink(Cairo.Context cr, int offset_x, int offset_y) {
            Gtk.StyleContext sc = this.get_style_context();
            sc.save();
            if (this.is_connected())
                sc.set_state(Gtk.StateFlags.CHECKED);
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

        public bool motion_notify_event(Gdk.EventMotion e) {
            // Determine x/y coords relative to this node's zero coordinates
            Gtk.Allocation alloc;
            this.get_node_allocation(out alloc);
            int local_x = (int)e.x - alloc.x;
            int local_y = (int)e.y - alloc.y;
            return true;
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
         * Draw this node on the given cairo context
         * TODO: implement
         */
        public void draw_node(Cairo.Context cr) {
            Gtk.Allocation alloc;
            this.get_node_allocation(out alloc);

            int y_offset = 0;
            foreach (Sink s in this.sinks) {
                s.draw_sink(cr, alloc.x, alloc.y+y_offset);
                y_offset += s.get_min_height();
            }
            foreach (Source s in this.sources) {
                s.draw_source(cr, alloc.x, alloc.y+y_offset, alloc.width);
                y_offset += s.get_min_height();
            }

            Gtk.StyleContext sc = this.get_style_context();
            sc.save();
            sc.render_background(cr, alloc.x, alloc.y, alloc.width, alloc.height);
            sc.add_class(Gtk.STYLE_CLASS_FRAME);
            sc.render_frame(cr, alloc.x, alloc.y, alloc.width, alloc.height);
            sc.restore();

            this.propagate_draw(this.get_child(), cr);
        }
    }

    /**
     * A Gtk Widget that shows nodes and their connections to the user
     * It also lets the user edit said connections.
     */
    public class NodeView : Gtk.Widget {
        private Gee.ArrayList<Node> nodes = new Gee.ArrayList<Node>();
   
        // The node that is currently being dragged around
        private const int DRAG_THRESHOLD = 3;
        private Node? drag_node = null;
        private bool drag_threshold_fulfilled = false;
        // Coordinates where the drag started
        private double drag_start_x = 0;
        private double drag_start_y = 0;
        // Difference from the chosen drag-point to the 
        // upper left corner of the drag_node
        private int drag_diff_x = 0;
        private int drag_diff_y = 0;

        public NodeView() {
            base();
            this.set_size_request(100,100);
        }

        public void add_node(Node n) {
            if (!this.nodes.contains(n))
                this.nodes.add(n);
        }

        public void remove_node(Node n) {
            if (this.nodes.contains(n))
                this.nodes.remove(n);
        }

        private Node? get_node_on_position(double x,double y) {
            Gtk.Allocation alloc;
            foreach (Node n in this.nodes) {
                n.get_node_allocation(out alloc);
                if ( x >= alloc.x && y >= alloc.y &&
                         x <= alloc.x + alloc.width && y <= alloc.y + alloc.height ) {
                    stdout.printf("habemus node\n");
                    return n;
                }
            }
            return null;
        }

        public override bool button_press_event(Gdk.EventButton e) {
            stdout.printf("press %d %d\n",(int)e.x, (int)e.y);
            Node? n = this.get_node_on_position(e.x, e.y);
            // Set a new drag node.
            if (n != null && this.drag_node == null) {
                this.drag_node = n;
                Gtk.Allocation alloc;
                this.drag_node.get_node_allocation(out alloc);
                this.drag_start_x = e.x;
                this.drag_start_y = e.y;
                this.drag_diff_x = (int)this.drag_start_x - alloc.x;
                this.drag_diff_y = (int)this.drag_start_y - alloc.y;
            }
            return false;
        }

        public override bool button_release_event(Gdk.EventButton e) {
            this.stop_dragging();
            stdout.printf("release %d %d\n", (int)e.x, (int)e.y);
            return false;
        }

        private void stop_dragging() {
            this.drag_start_x = 0;
            this.drag_start_y = 0;
            this.drag_diff_x = 0;
            this.drag_diff_y = 0;
            this.drag_node = null;
            this.drag_threshold_fulfilled = false;
        }

        public override bool motion_notify_event(Gdk.EventMotion e) {
            stdout.printf("motion %d %d\n", (int)e.x, (int)e.y);

            // Check if we are on a node. If yes, check if we are
            // currently pointing on a dock. if this is true, we
            // Want to draw a new connector instead of dragging the node
            Node? n = this.get_node_on_position(e.x, e.y);
            if (n != null) {
                n.motion_notify_event(e);
            }

            // Check if the cursor has been dragged a few pixels (defined by DRAG_THRESHOLD)
            // If yes, actually start dragging
            if ( this.drag_node != null
                    && (Math.fabs(drag_start_x - e.x) > NodeView.DRAG_THRESHOLD
                    ||  Math.fabs(drag_start_y - e.y) > NodeView.DRAG_THRESHOLD )) {
                this.drag_threshold_fulfilled = true;
            }

            // Actually move the node
            if (this.drag_threshold_fulfilled && this.drag_node != null) {
                Gtk.Allocation alloc;
                this.drag_node.get_node_allocation(out alloc);
                alloc.x = (int)e.x - this.drag_diff_x;
                alloc.y = (int)e.y - this.drag_diff_y;
                this.drag_node.set_node_allocation(alloc);
                this.queue_draw();
            }
            return false;
        }

        public override bool leave_notify_event(Gdk.EventCrossing e) {
            this.stop_dragging();
            return false;
        }

        public override bool draw(Cairo.Context cr) {
            Gtk.StyleContext sc = this.get_style_context();
            Gdk.RGBA bg = sc.get_background_color(Gtk.StateFlags.NORMAL);
            cr.set_source_rgba(bg.red, bg.green, bg.blue, bg.alpha);
            cr.paint();
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);
            stdout.printf("%d %d\n", alloc.height, alloc.width);
            foreach (Node n in this.nodes)
                n.draw_node(cr);
            return true;
        }

        public override void realize() {
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);
            var attr = Gdk.WindowAttr();
            attr.window_type = Gdk.WindowType.CHILD;
            attr.x = alloc.x;
            attr.y = alloc.y;
            attr.width = alloc.width;
            attr.height = alloc.height;
            attr.visual = this.get_visual();
            attr.event_mask = this.get_events()
                 | Gdk.EventMask.POINTER_MOTION_MASK
                 | Gdk.EventMask.BUTTON_PRESS_MASK
                 | Gdk.EventMask.BUTTON_RELEASE_MASK
                 | Gdk.EventMask.LEAVE_NOTIFY_MASK;
            Gdk.WindowAttributesType mask = Gdk.WindowAttributesType.X 
                 | Gdk.WindowAttributesType.X 
                 | Gdk.WindowAttributesType.VISUAL;
            var window = new Gdk.Window(this.get_parent_window(), attr, mask);
            this.set_window(window);
            this.register_window(window);
            this.set_realized(true);
            window.set_background_pattern(null);
        }
    }
}
