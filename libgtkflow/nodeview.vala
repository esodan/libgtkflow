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
     * A Gtk Widget that shows nodes and their connections to the user
     * It also lets the user edit said connections.
     */
    public class NodeView : Gtk.Container, Gtk.Scrollable {
        private List<INode> nodes = new List<INode>();
   
        // The node that is currently being dragged around
        private const int DRAG_THRESHOLD = 3;
        private INode? drag_node = null;
        private bool drag_threshold_fulfilled = false;
        // Coordinates where the drag started
        private double drag_start_x = 0;
        private double drag_start_y = 0;
        // Difference from the chosen drag-point to the 
        // upper left corner of the drag_node
        private int drag_diff_x = 0;
        private int drag_diff_y = 0;

        // Remember if a closebutton was pressed
        private bool close_button_pressed = false;
        // Remember if we are resizing a node
        private INode? resize_node = null;
        private int resize_start_x = 0;
        private int resize_start_y = 0;

        // Remember the last dock the mouse hovered over, so we can unhighlight it
        private Dock? hovered_dock = null;

        // The dock that we are targeting for dragging a new connector
        private Dock? drag_dock = null;
        // The dock that we are targeting to drop a connector on
        private Dock? drop_dock = null;
        // The connector that is being used to draw a non-established connection
        private Gtk.Allocation? temp_connector = null;

        public Gtk.Adjustment _hadjustment = null;
        public Gtk.Adjustment hadjustment {
            get {
                return this._hadjustment;
            }
            set {
                this._hadjustment = value;
                this._hadjustment.value_changed.connect(this.queue_draw);
            }
        }
        public Gtk.Adjustment _vadjustment = null;
        public Gtk.Adjustment vadjustment {
            get {
                return this._vadjustment;

            }
            set {
                this._vadjustment = value;
                this._vadjustment.value_changed.connect(this.queue_draw);
            }
        }
        public Gtk.ScrollablePolicy hscroll_policy {get; set;
                                                    default=Gtk.ScrollablePolicy.MINIMUM;}
        public Gtk.ScrollablePolicy vscroll_policy {get; set;
                                                    default=Gtk.ScrollablePolicy.MINIMUM;}

        /**
         * Determines whether the displayed Nodes can be edited by the user
         * e.g. alter their positions by dragging and dropping or drawing
         * new collections or erasing old ones
         */
        public bool editable {get; set; default=true;}

        public NodeView() {
            Object();
            this.vadjustment = new Gtk.Adjustment(0, 0, 100, 50, 100, 100);
            this.hadjustment = new Gtk.Adjustment(0, 0, 100, 50, 100, 100);
            this.set_size_request(100,100);
        }

        public override void add(Gtk.Widget w) {
            assert(w is INode);
            this.add_node(w as INode);
            w.set_parent(this);
        }

        public override void remove(Gtk.Widget w) {
            assert(w is INode);
            this.remove_node(w as INode);
            w.unparent();
        }

        private void add_node(INode n) {
            if (this.nodes.index(n) == -1) {
                this.nodes.insert(n,0);
                n.set_node_view(this);
                this.add(n as Gtk.Widget);
            }
            this.queue_draw();
        }

        private void remove_node(INode n) {
            if (this.nodes.index(n) != -1) {
                this.nodes.remove(n);
                n.set_node_view(null);
                this.remove(n as Gtk.Widget);
            }
            this.queue_draw();
        }

        private INode? get_node_on_position(double x,double y) {
            Gtk.Allocation alloc;
            x += this.hadjustment.value;
            y += this.vadjustment.value;
            foreach (INode n in this.nodes) {
                n.get_node_allocation(out alloc);
                if ( x >= alloc.x && y >= alloc.y &&
                         x <= alloc.x + alloc.width && y <= alloc.y + alloc.height ) {
                    return n;
                }
            }
            return null;
        }

        public override bool button_press_event(Gdk.EventButton e) {
            if (!this.editable)
                return false;
            INode? n = this.get_node_on_position(e.x, e.y);
            Dock? targeted_dock = null;
            Gdk.Point pos = {(int)e.x,(int)e.y};
            if (n != null) {
                if (n.is_on_closebutton(pos))
                    this.close_button_pressed = true;
                targeted_dock = n.get_dock_on_position(pos);
                if (targeted_dock != null) {
                    this.drag_dock = targeted_dock;
                    this.drag_dock.pressed = true;
                    Gdk.Point startpos;
                    if (this.drag_dock is Sink && this.drag_dock.is_connected()){
                        Source s = (this.drag_dock as Sink).source;
                        Node srcnode = s.get_node();
                        try {
                            startpos = srcnode.get_dock_position(s);
                        } catch (NodeError e) {
                            warning("No dock on position. Aborting drag");
                            return false;
                        }
                        this.temp_connector = {startpos.x, startpos.y,
                                               (int)e.x-startpos.x, (int)e.y-startpos.y};
                    } else {
                        try {
                            startpos = n.get_dock_position(this.drag_dock);
                        } catch (NodeError e) {
                            warning("No dock on position. Aborting drag");
                            return false;
                        }
                        this.temp_connector = {startpos.x, startpos.y, 0, 0};
                    }
                    this.queue_draw();
                    return true;
                }
            }
            // Set a new drag node.
            if (n != null) {
                Gtk.Allocation alloc;
                if (n.is_on_resize_handle(pos) && this.resize_node == null) {
                    this.resize_node = n;
                    this.resize_node.get_node_allocation(out alloc);
                    this.resize_start_x = alloc.width;
                    this.resize_start_y = alloc.height;
                } else if (this.resize_node == null && this.drag_node == null) {
                    this.drag_node = n;
                    this.drag_node.get_node_allocation(out alloc);
                } else {
                    return false;
                }
                this.drag_start_x = e.x;
                this.drag_start_y = e.y;
                this.drag_diff_x = (int)this.drag_start_x - alloc.x;
                this.drag_diff_y = (int)this.drag_start_y - alloc.y;
            }
            return false;
        }

        public override bool button_release_event(Gdk.EventButton e) {
            if (!this.editable)
                return false;
            // Determine if this was a closebutton press
            if (this.close_button_pressed) {
                INode? n = this.get_node_on_position(e.x, e.y);
                if (n != null) {
                    Gdk.Point pos = {(int)e.x,(int)e.y};
                    if (n.is_on_closebutton(pos)) {
                        n.disconnect_all();
                        assert (n is Gtk.Widget);
                        (n as Gtk.Widget).destroy();
                        this.queue_draw();
                        this.close_button_pressed = false;
                        return true;
                    }
                }
            }
            // Try to build a new connection
            if (this.drag_dock != null) {
                try {
                    if (this.drag_dock is Source && this.drop_dock is Sink) {
                        (this.drag_dock as Source).add_sink(this.drop_dock as Sink);
                    }
                    else if (this.drag_dock is Sink && this.drop_dock is Source) {
                        (this.drop_dock as Source).add_sink(this.drag_dock as Sink);
                    }
                    else if (this.drag_dock is Sink && this.drop_dock is Sink) {
                        Source? src = (this.drag_dock as Sink).source;
                        if (src != null) {
                            src.remove_sink(this.drag_dock as Sink);
                            src.add_sink(this.drop_dock as Sink);
                        }
                    }
                    else if (this.drag_dock is Sink && this.drop_dock == null) {
                        Source? src = (this.drag_dock as Sink).source;
                        if (src != null) {
                            src.remove_sink(this.drag_dock as Sink);
                        }
                    }
                } catch (NodeError e) {
                    warning(e.message);
                }
            }
            this.stop_dragging();
            this.queue_draw();
            return false;
        }

        private void stop_dragging() {
            this.drag_start_x = 0;
            this.drag_start_y = 0;
            this.drag_diff_x = 0;
            this.drag_diff_y = 0;
            this.drag_node = null;
            if (this.drag_dock != null) {
                this.drag_dock.pressed = false;
            }
            this.drag_dock = null;
            if (this.drop_dock != null) {
                this.drop_dock.pressed = false;
            }
            this.drop_dock = null;
            this.temp_connector = null;
            this.drag_threshold_fulfilled = false;
            this.resize_node = null;
            this.get_window().set_cursor(null);
        }

        private Gdk.Cursor resize_cursor = null;
        private Gdk.Cursor? get_resize_cursor() {
            if (resize_cursor == null && this.get_realized()) {
                resize_cursor = new Gdk.Cursor.for_display(
                    this.get_window().get_display(),
                    Gdk.CursorType.BOTTOM_RIGHT_CORNER
                );
            }
            return resize_cursor;
        }

        public override bool motion_notify_event(Gdk.EventMotion e) {
            if (!this.editable)
                return false;
            // Check if we are on a node. If yes, check if we are
            // currently pointing on a dock. if this is true, we
            // Want to draw a new connector instead of dragging the node
            INode? n = this.get_node_on_position(e.x, e.y);
            Dock? targeted_dock = null;
            if (n != null) {
                Gdk.Point pos = {(int)e.x, (int)e.y};
                if (!n.is_on_closebutton(pos))
                    this.close_button_pressed = false;
                // Update cursor if we are on the resize area
                if (n.is_on_resize_handle(pos))
                    this.get_window().set_cursor(this.get_resize_cursor());
                else if (this.resize_node == null)
                    this.get_window().set_cursor(null);
                targeted_dock = n.get_dock_on_position(pos);
                if (this.drag_dock == null && targeted_dock != this.hovered_dock) {
                    this.set_hovered_dock(targeted_dock);
                }
                else if (this.drag_dock != null && targeted_dock != null
                      && targeted_dock != this.hovered_dock
                      && this.is_suitable_target(this.drag_dock, targeted_dock)) {
                    this.set_hovered_dock(targeted_dock);
                }
            } else {
                // If we are leaving the node we will also have to
                // un-highlight the last hovered dock
                if (this.hovered_dock != null)
                    this.hovered_dock.highlight = false;
                this.hovered_dock = null;
                this.queue_draw();
                // Update cursor to be default as we are guaranteed not on any
                // resize handle outside of any node.
                // The check for resize node is a cosmetical fix. If there is a
                // Node bing resized in haste, the cursor tends to flicker
                if (this.resize_node == null)
                    this.get_window().set_cursor(null);
            }

            // Check if the cursor has been dragged a few pixels (defined by DRAG_THRESHOLD)
            // If yes, actually start dragging
            if ( ( this.drag_node != null || this.drag_dock != null || this.resize_node != null)
                    && (Math.fabs(drag_start_x - e.x) > NodeView.DRAG_THRESHOLD
                    ||  Math.fabs(drag_start_y - e.y) > NodeView.DRAG_THRESHOLD )) {
                this.drag_threshold_fulfilled = true;
            }

            // Actually something
            if (this.drag_threshold_fulfilled ) {
                if (this.drag_node != null) {
                    // Actually move the node
                    Gtk.Allocation alloc;
                    this.drag_node.get_node_allocation(out alloc);
                    alloc.x = (int)e.x - this.drag_diff_x;
                    alloc.y = (int)e.y - this.drag_diff_y;
                    this.drag_node.set_node_allocation(alloc);
                    this.recalculate_size();
                    this.queue_draw();
                }
                if (this.drag_dock != null) {
                    // Manipulate the temporary connector
                    this.temp_connector.width = (int)e.x-this.temp_connector.x;
                    this.temp_connector.height = (int)e.y-this.temp_connector.y;
                    if (targeted_dock == null) {
                        this.set_drop_dock(null);
                    }
                    else if (this.is_suitable_target(this.drag_dock, targeted_dock))
                        this.set_drop_dock(targeted_dock);

                    this.queue_draw();
                }
                if (this.resize_node != null) {
                    // resize the node
                    Gtk.Allocation alloc;
                    this.resize_node.get_node_allocation(out alloc);
                    alloc.width =  resize_start_x + (int)e.x - (int)this.drag_start_x;
                    alloc.height = resize_start_y + (int)e.y - (int)this.drag_start_y;
                    this.resize_node.set_node_allocation(alloc);
                    this.queue_draw();
                }
            }
            return false;
        }

        private void recalculate_size() {
            double x_min = 0, x_max = 0, y_min = 0, y_max = 0;
            Gtk.Allocation alloc;
            foreach (INode n in this.nodes) {
                n.get_node_allocation(out alloc);
                x_min = Math.fmin(x_min, alloc.x);
                x_max = Math.fmax(x_max, alloc.x+alloc.width);
                y_min = Math.fmin(y_min, alloc.y);
                y_max = Math.fmax(y_max, alloc.y+alloc.height);
            }
            this.hadjustment.lower = x_min;
            this.hadjustment.upper = x_max;
            this.vadjustment.lower = y_min;
            this.vadjustment.upper = y_max;
        }

        /**
         * Determines wheter one dock can be dropped on another
         */
        private bool is_suitable_target (Dock from, Dock to) {
            // Check whether the docks have the same type
            if (!from.has_same_type(to))
                return false;
            // Check if the target would lead to a recursion
            if (   from.get_node().is_recursive(to.get_node())
                || to.get_node().is_recursive(from.get_node()))
                return false;
            // If the from from-target is a sink, check if the
            // to target is either a source which does not belong to the own node
            // or if the to target is another sink (this is valid as we can
            // move a connection from one sink to another
            if (from is Sink
                    && ((to is Sink
                    && to != from)
                    || (to is Source
                    && !to.get_node().has_dock(from)))) {
                return true;
            }
            // Check if the from-target is a source. if yes, make sure the
            // to-target is a sink and it does not belong to the own node
            else if (from is Source
                    && to is Sink
                    && !to.get_node().has_dock(from)) {
                return true;
            }
            return false;
        }

        /**
         * Sets the dock that is currently being hovered over to drop
         * a connector on
         */
        private void set_drop_dock(Dock? d) {
            if (this.drop_dock != null)
                this.drop_dock.pressed = false;
            this.drop_dock = d;
            if (this.drop_dock != null)
                this.drop_dock.pressed = true;
            this.queue_draw();
        }

        /**
         * Sets the dock that is currently being hovered over
         */
        private void set_hovered_dock(Dock? d) {
            if (this.hovered_dock != null)
                this.hovered_dock.highlight = false;
            this.hovered_dock = d;
            if (this.hovered_dock != null)
                this.hovered_dock.highlight = true;
            this.queue_draw();
        }

        public override bool draw(Cairo.Context cr) {
            Gtk.StyleContext sc = this.get_style_context();
            Gdk.RGBA bg = sc.get_background_color(Gtk.StateFlags.NORMAL);
            cr.set_source_rgba(bg.red, bg.green, bg.blue, bg.alpha);
            cr.paint();
            // Draw nodes
            this.nodes.reverse();
            foreach (INode n in this.nodes)
                n.draw_node(cr);
            this.nodes.reverse();
            // Draw connectors
            foreach (INode n in this.nodes) {
                foreach(Source source in n.get_sources()) {
                    Gdk.Point source_pos = {0,0};
                    try {
                        source_pos = n.get_dock_position(source);
                    } catch (NodeError e) {
                        warning("No dock on position. Ommiting connector");
                        continue;
                    }
                    foreach(Sink sink in source.get_sinks()) {
                        // Don't draw the connection to a sink if we are dragging it
                        if (sink == this.drag_dock)
                            continue;
                        Node? sink_node = sink.get_node();
                        Gdk.Point sink_pos = {0,0};
                        try {
                            sink_pos = sink_node.get_dock_position(sink);
                        } catch (NodeError e) {
                            warning("No dock on position. Ommiting connector");
                            continue;
                        }
                        int w = sink_pos.x - source_pos.x;
                        int h = sink_pos.y - source_pos.y;
                        cr.move_to(source_pos.x, source_pos.y);
                        cr.rel_curve_to(w,0,0,h,w,h);
                        cr.stroke();
                    }
                }
            }
            // Draw temporary connector if any
            if (this.temp_connector != null) {
                int w = this.temp_connector.width;
                int h = this.temp_connector.height;
                cr.move_to(this.temp_connector.x, this.temp_connector.y);
                cr.rel_curve_to(w,0,0,h,w,h);
                cr.stroke();
            }
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
