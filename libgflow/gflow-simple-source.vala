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
     * A simple implementation of {@link GtkFlow.Source}.
     */
    public class SimpleSource : Object, Dock, Source {
        // Dock interface
        protected GLib.Value? _val;
        protected GLib.Value? _initial;
        protected bool _valid = false;

        public string? name { get; set; }
        public bool highlight { get; set; }
        public bool active {get; set; default=false;}
        public weak Node? node { get; set; }
        public GLib.Value? val {
          get { return _val; }
          set {
            if (!_val.holds (value.type ())) return;
            _val = value;
            changed ();
          }
        }
        public SimpleSource (GLib.Value initial) {
          _initial = initial;
          _val = _initial;
        }
        public GLib.Value? initial { get { return _initial; } }
        public bool valid { get { return _valid; } }
        // Source interface
        private List<Sink> _sinks = new List<Sink> ();
        public List<Sink> sinks { get { return _sinks; } }

        protected void add_sink (Sink s) throws Error
        {
            if (this.val.type() != s.val.type()) {
                throw new NodeError.INCOMPATIBLE_SINKTYPE(
                    "Can't connect. Sink has type %s while Source has type %s".printf(
                        s.val.type().name(), this.val.type().name()
                    )
                );
            }
            this.sinks.append (s);
            if (this.valid) {
                s.val = this.val;
            }
            connected ((Dock) s);
        }
        protected void remove_sink (Sink s) throws GLib.Error
        {
            if (this.sinks.index(s) != -1)
                this.sinks.remove(s);
            if (s.is_connected_to(this))
                s.disconnect (this);
            this.disconnected(s);
        }
        // FIXME This should not be set by users is a mutter of test to know if source should work
        public new void set_valid() {
            this._valid = true;
        }
        /**
         * Returns true if this Source is connected to the given Sink
         */
        public bool is_connected_to (Dock dock) {
            if (!(dock is Sink)) return false;
            return this.sinks.index((Sink) dock) != -1;
        }

        /**
         * Returns true if this Source is connected to one or more Sinks
         */
        public bool is_connected () {
            return this.sinks.length () > 0;
        }
        // FIXME: Added to implement the one on Dock - Review
        public void invalidate () { _valid = false; }
        // FIXME Added to simplify Source interface
        public new void disconnect (Dock dock) throws GLib.Error
        {
          if (!dock.is_connected_to (this)) return;
          if (dock is Sink) {
            remove_sink ((Sink) dock);
            if (sinks.length () == 0) disconnected (dock);
          }
        }
        public new void connect (Dock dock) throws GLib.Error
        {
          if (dock.is_connected_to (this)) return;
          if (dock is Sink) {
            add_sink ((Sink) dock);
            connected (dock);
          }
        }
        /**
         * FIXME This could be removed and make connected Dock to lisen updated () signal
         */
        public void set_value (GLib.Value v) throws GLib.Error
        {
            if (this.val.type() != v.type())
                throw new NodeError.INCOMPATIBLE_VALUE(
                    "Cannot set a %s value to this %s Source".printf(
                        v.type().name(),this.val.type().name())
                );
            this.val = v;
            foreach (Sink s in this.sinks)
                s.val = v;
            updated ();
        }
    }
}
