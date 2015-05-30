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
    public class NodeView : Gtk.Container {
        private List<Node> nodes = new List<Node>();
   
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

        // Remember the last dock the mouse hovered over, so we can unhighlight it
        private Dock? hovered_dock = null;

        // The dock that we are targeting for dragging a new connector
        private Dock? drag_dock = null;
        // The dock that we are targeting to drop a connector on
        private Dock? drop_dock = null;
        // The connector that is being used to draw a non-established connection
        private Gtk.Allocation? temp_connector = null;

        public NodeView() {
            Object();
            this.set_size_request(100,100);
        }

        public override void add(Gtk.Widget w) {
            assert(w is Node);
            this.add_node(w as Node);
            w.set_parent(this);
        }

        public override void remove(Gtk.Widget w) {
            assert(w is Node);
            this.remove_node(w as Node);
            w.unparent();
        }

        private void add_node(Node n) {
            if (this.nodes.index(n) == -1) {
                this.nodes.insert(n,0);
                n.set_node_view(this);
                this.add(n);
            }
            this.queue_draw();
        }

        private void remove_node(Node n) {
            if (this.nodes.index(n) != -1) {
                this.nodes.remove(n);
                n.set_node_view(null);
                this.remove(n);
            }
            this.queue_draw();
        }

        private Node? get_node_on_position(double x,double y) {
            Gtk.Allocation alloc;
            foreach (Node n in this.nodes) {
                n.get_node_allocation(out alloc);
                if ( x >= alloc.x && y >= alloc.y &&
                         x <= alloc.x + alloc.width && y <= alloc.y + alloc.height ) {
                    return n;
                }
            }
            return null;
        }

        public override bool button_press_event(Gdk.EventButton e) {
            Node? n = this.get_node_on_position(e.x, e.y);
            Dock? targeted_dock = null;
            if (n != null) {
                Gdk.Point pos = {(int)e.x,(int)e.y};
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
        }

        public override bool motion_notify_event(Gdk.EventMotion e) {

            // Check if we are on a node. If yes, check if we are
            // currently pointing on a dock. if this is true, we
            // Want to draw a new connector instead of dragging the node
            Node? n = this.get_node_on_position(e.x, e.y);
            Dock? targeted_dock = null;
            if (n != null) {
                //n.motion_notify_event(e);
                Gdk.Point pos = {(int)e.x, (int)e.y};
                targeted_dock = n.get_dock_on_position(pos);
                if (targeted_dock != this.hovered_dock) {
                    this.set_hovered_dock(targeted_dock);
                }
            } else {
                // If we are leaving the node we will also have to
                // un-highlight the last hovered dock
                if (this.hovered_dock != null)
                    this.hovered_dock.highlight = false;
                this.hovered_dock = null;
                this.queue_draw();
            }

            // Check if the cursor has been dragged a few pixels (defined by DRAG_THRESHOLD)
            // If yes, actually start dragging
            if ( ( this.drag_node != null || this.drag_dock != null )
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
            }
            return false;
        }

        /**
         * Determines wheter one dock can be dropped on another
         */
        private bool is_suitable_target (Dock from, Dock to) {
            // Check whether the docks have the same type
            if (!from.has_same_type(to))
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

        public override bool leave_notify_event(Gdk.EventCrossing e) {
            if (e.detail != Gdk.NotifyType.INFERIOR)
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
            // Draw nodes
            this.nodes.reverse();
            foreach (Node n in this.nodes)
                n.draw_node(cr);
            this.nodes.reverse();
            // Draw connectors
            foreach (Node n in this.nodes) {
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
                cr.rel_curve_to(this.temp_connector.width,0,0,h,w,h);
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
