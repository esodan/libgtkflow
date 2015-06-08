/********************************************************************
# Copyright 2014 Daniel 'grindhold' Brendle, 2015 Daniel Espinosa <esodan@gmail.com>
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
namespace GFlow {
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
     * This is done by adding Sources and Sinks to it. The inner logic of // FIXME;
     */
    public interface Node : GLib.Object {
        public signal void sinks_changed ();
        public signal void sources_changed ();
        public abstract string name { get; set; }
        public abstract void disconnect_all ();
        public abstract bool is_recursive (Node from, bool initial=false);
        public abstract Dock? get_dock (string name);
        public abstract bool has_dock(Dock d);
        public abstract unowned List<Source> get_sources ();
        public abstract add_source (Source source);
        public abstract remove_source (Source source);
        public abstract bool has_source (Source s);
        public abstract add_sink (Sink sink);
        public abstract bool has_sink (Sink s);
        public abstract remove_sink (Sink sink);
    }

    /**
     * Represents an element that can generate, process or receive data
     * This is done by adding Sources and Sinks to it. The inner logic of
     * The node can be represented towards the user as arbitrary Gtk widget.
     */
    public class SimpleNode : Object, Node {
        private List<Source> sources = new List<Source>();
        private List<Sink> sinks = new List<Sink>();

        private NodeView? node_view = null;

        private Gtk.Allocation node_allocation;

        private string title = "";
        private Pango.Layout layout;

        public string name { get; set; default="SimpleNode";}
        /**
         * FIXME:*
         */
        public void add_source(Source s) throws NodeError {
            if (s.get_node() != null)
                throw new NodeError.DOCK_ALREADY_BOUND_TO_NODE("This Source is already bound");
            if (this.sources.index(s) != -1)
                throw new NodeError.ALREADY_HAS_DOCK("This node already has this source");
            sources.append(s);
            s.set_node(this);
            s.update_layout();
            sources_changed ();
        }
        /**
         * FIXME:*
         */
        public void add_sink (Sink s) throws NodeError {
            if (s.get_node() != null)
                throw new NodeError.DOCK_ALREADY_BOUND_TO_NODE("This Sink is already bound" );
            if (this.sinks.index(s) != -1)
                throw new NodeError.ALREADY_HAS_DOCK("This node already has this sink");
            sinks.append(s);
            s.set_node(this); // FIXME: send a signal to update_layout and recalculate_size
            sinks_changed ();
        }

        public void remove_source(Source s) throws NodeError {
            if (this.sources.index(s) == -1)
                throw new NodeError.NO_SUCH_DOCK("This node doesn't have this source");
            sources.remove(s);
            s.set_node(null); // FIXME: send a signal to update_layout and recalculate_size
            sources_changed ();
        }

        public void remove_sink(Sink s) throws NodeError {
            if (this.sinks.index(s) == -1)
                throw new NodeError.NO_SUCH_DOCK("This node doesn't have this sink");
            sinks.remove(s);
            s.set_node(null); // FIXME: send a signal to update_layout and recalculate_size
            sinks_changed ();
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
  }
}
