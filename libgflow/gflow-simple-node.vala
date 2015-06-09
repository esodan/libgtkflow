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

namespace GFlow {
    /**
     * Represents an element that can generate, process or receive data
     * This is done by adding Sources and Sinks to it. The inner logic of
     * The node can be represented towards the user as arbitrary Gtk widget.
     */
    public class SimpleNode : Object, Node
    {
        private List<Source> sources = new List<Source>();
        private List<Sink> sinks = new List<Sink>();

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
