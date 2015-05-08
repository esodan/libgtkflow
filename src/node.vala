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
    public abstract class Dock : GLib.Object {
        public const int HEIGHT = 10;

        private int x = 0;
        private int y = 0;

        public virtual string label {get;set;default="";}

        /**
         * A reference to the node this Dock resides in
         */
        protected weak Node? node = null;

        /**
         * The value that is stored in this Dock
         */
        protected GLib.Value val;

        /**
         * Initialize this with a value
         */
        protected Dock(GLib.Value initial) {
            this.val = initial;
        }

        /**
         * This signal is being triggered, when there is a connection being established
         * from or to this Dock.
         */
        public signal void connected(Dock d);

        public abstract bool is_connected();
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
    }

    /**
     * Represents an element that can generate, process or receive data
     * This is done by adding Sources and Sinks to it. The inner logic of
     * The node can be represented towards the user as arbitrary Gtk widget.
     */
    public class Node : Gtk.Bin {
        private int x = 0;
        private int y = 0;

        private Gee.ArrayList<Source> sources = new Gee.ArrayList<Source>();
        private Gee.ArrayList<Sink> sinks = new Gee.ArrayList<Sink>();

        public Node () {
        }

        public void add_source(Source s) {
            if (!this.sources.contains(s))
                sources.add(s);
        }

        public void add_sink(Sink s) {
            if (!this.sinks.contains(s))
                sinks.add(s);
        }

        public void remove_source(Source s) {
            if (this.sources.contains(s))
                sources.remove(s);
        }

        public void remove_sink(Sink s) {
            if (this.sinks.contains(s))
                sinks.remove(s);
        }

        /**
         * Draw this node on the given cairo context
         * TODO: implement
         */
        public void draw_node(Cairo.Context cr) {
            //Determine height of widget
            Gtk.Widget child = this.get_child();
            uint min_width, max_width, min_height, max_height = 10;
            min_width = max_width = 2 * this.border_width;
            min_height = max_height = 2 * this.border_width;
            if (child != null) {
                int cmw, cmh, cpw, cph = 0;
                child.get_preferred_width(out cmw, out cpw);
                child.get_preferred_height(out cmh, out cph);
                min_width += cmw;
                min_height += cmh;
                max_width += cpw;
                max_height += cph;
            }
            // TODO: correctly determine the height of the docks
            min_height += this.sinks.size * Dock.HEIGHT;
            max_height += this.sources.size * Dock.HEIGHT;

            stdout.printf("minw %u minh %u maxw %u maxh %u\n", min_width, min_height, max_width, max_height);

            Gtk.StyleContext sc = this.get_style_context();
            cr.set_source_rgba(0,1,0,1.0);
            cr.rectangle(30,30,max_width,max_height);
            cr.fill();
            sc.save();
            sc.render_background(cr, this.x, this.y, 100,100);
            sc.set_state(Gtk.StateFlags.INSENSITIVE);
            sc.add_class(Gtk.STYLE_CLASS_FRAME);
            sc.render_frame(cr, this.x, this.y, 100,100);
            sc.restore();

            sc.save();
            sc.set_state(Gtk.StateFlags.CHECKED);
            sc.add_class(Gtk.STYLE_CLASS_RADIO);
            sc.render_option(cr, 20,20,10,10);
            sc.restore();

            sc.save();
            sc.set_state(Gtk.StateFlags.ACTIVE);
            sc.add_class(Gtk.STYLE_CLASS_RADIO);
            sc.render_option(cr, 20,50,10,10);
            sc.restore();
            sc.save();
            sc.set_state(Gtk.StateFlags.PRELIGHT);
            sc.add_class(Gtk.STYLE_CLASS_RADIO);
            sc.render_option(cr, 20,40,10,10);
            sc.restore();
            sc.save();
            sc.set_state(Gtk.StateFlags.ACTIVE | Gtk.StateFlags.CHECKED);
            sc.add_class(Gtk.STYLE_CLASS_RADIO);
            sc.render_option(cr, 20,70,10,10);
            sc.restore();
        }
    }

    /**
     * A Gtk Widget that shows nodes and their connections to the user
     * It also lets the user edit said connections.
     */
    public class NodeView : Gtk.Widget {
        private Gee.ArrayList<Node> nodes = new Gee.ArrayList<Node>();


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
            attr.event_mask = this.get_events();
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
