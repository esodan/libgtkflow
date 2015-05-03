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
     * in this endpoint is stored as GLib.Variant. Only Docks that contain
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
        protected GLib.Variant val;

        /**
         * Make variant typecheck of value available to the outside world
         */
        public virtual bool is_of_type(GLib.VariantType v){
            return this.val.is_of_type(v);
        }
        public signal void connected(Dock d);
    }

    /**
     * The Source is a special Type of Dock that provides data.
     * A Source can provide a multitude of Sinks with data.
     */
    public abstract class Source : Dock {
        private Sink[] s;
        public virtual void add_sink(Sink s) throws NodeError {
        }
    }

    /**
     * A Sink is a special Type of Dock that receives data from
     * A source in order to let it either 
     */
    public abstract class Sink : Dock {
        /**
         * The Source that this Sink draws its data from
         */
        private weak Source? _s;
        public weak Source? s {
            get{
                return this._s;
            }
            set{
                this._s = value;
                this.connected(value);
            }
            default=null;
        }

        public virtual void set_source(Source s) throws NodeError{
        }
        public signal void changed(GLib.Variant v);
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
    }
}
