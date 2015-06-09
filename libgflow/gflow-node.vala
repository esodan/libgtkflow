/********************************************************************
# Copyright 2014 Daniel 'grindhold' Brendle, 2015 Daniel Espinosa <esodan@gmail.com>
#
# This file is part of libgflow.
#
# libgflow is free software: you can redistribute it and/or
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
}
