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
        INCOMPATIBLE_SINKTYPE
    }

    /**
     * This class represents an endpoint of a node. These endpoints can be
     * connected in order to let them exchange data. The data contained
     * in this endpoint is stored as GLib.Value. Only Docks that contain
     * data with the same VariantType can be interconnected.
     */
    public abstract class Dock : GLib.Object {
        public int x = 0;
        public int y = 0;

        /**
         * A reference to the node this Dock resides in
         */
        protected weak Node? node = null;

        /**
         * The value that is stored in this Dock
         */
        protected GLib.Value val;

        public Dock(GLib.Value initial) {
            this.val = initial;
        }

        /**
         * Make variant typecheck of value available to the outside world
         */
        public virtual bool is_of_type(GLib.Type v){
            return this.val.type() == v;
        }

        public virtual Type type() {
            return this.val.type();
        }

        public signal void connected(Dock d);
    }

    /**
     * The Source is a special Type of Dock that provides data.
     * A Source can provide a multitude of Sinks with data.
     */
    public class Source : Dock {
        private Gee.ArrayList<Sink> sinks;
        public virtual void add_sink(Sink s) throws NodeError {
            if (!this.sinks.contains(s))
                this.sinks.add(s);
        }

        public Source(GLib.Value initial) {
            base(initial);
            this.sinks = new Gee.ArrayList<Sink>();
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
            this._source = s;
            this.connected(s);
        }

        public signal void changed(GLib.Value v);
    }

    public class Node : GLib.Object {
        private int x = 0;
        private int y = 0;


        public void add_source(Source s) {
        }

        public void add_sink(Sink s) {
        }
    }

    public class NodeView : Gtk.Widget {
        public void add_node(Node n) {
        }

        public override bool draw(Cairo.Context cr) {
            return true;
        }
    }
}
