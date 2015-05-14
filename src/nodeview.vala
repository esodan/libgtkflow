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

        // Remember the last dock the mouse hovered over, so we can unhighlight it
        private Dock? hovered_dock = null;

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
            Dock? targeted_dock = null;
            if (n != null) {
                //n.motion_notify_event(e);
                Gdk.Point pos = {(int)e.x, (int)e.y};
                targeted_dock = n.get_dock_on_position(pos);
                if (targeted_dock != this.hovered_dock) {
                    if (this.hovered_dock != null)
                        this.hovered_dock.highlight = false;
                    this.hovered_dock = targeted_dock;
                    if (this.hovered_dock != null)
                        this.hovered_dock.highlight = true;
                    this.queue_draw();
                }
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
