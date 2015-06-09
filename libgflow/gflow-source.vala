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
     * The Source is a special Type of Dock that provides data.
     * A Source could be used by multitude of Sinks as a source of data. // FIXME Is this correct?
     */
    public interface Source : Object, Dock {
        /**
        * FIXME This should be read-only
        */
        private List<Sink> sinks = new List<Sink>();

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
            if (this.sinks.index(s) == -1)
                this.sinks.append(s);
            if (!s.connected_to(this))
                s.set_source(this);
            if (this.valid) {
                s.change_value(this.val);
            }
        }
/* FIXME This should not be set by user
        public new void set_valid() {
            this.valid = true;
        }*/

        public virtual void remove_sink(Sink s){
            if (this.sinks.index(s) != -1)
                this.sinks.remove(s);
            if (s.connected_to(this))
                s.unset_source();
            this.disconnected(s);
        }

        public virtual void remove_sinks () {
            foreach (Sink s in this.sinks)
                this.remove_sink (s);
        }

        /** FIXME May be the way to make sinks read-only is to return an owned copy of it to avoid writes on lists
         * Returns the sinks that this source is connected to
         */
        public virtual unowned List<Sink> get_sinks() {
            return this.sinks;
        }
    }
}
