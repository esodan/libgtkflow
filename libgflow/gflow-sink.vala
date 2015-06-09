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
     * A Sink is a special Type of Dock that receives data from
     * a source in order to let it either 
     */
    public interface Sink : Object, Dock {
        /**
         * The Source that this Sink draws its data from.
         *
         * Implementators: You should setup when a {@link GFlow.Source} is set
         * and when is set to null, you should release any connection from {@link GFlow.Source}.
         */
        public abstract weak Source? source { get; set; }

// FIXME: May avoid to rise error but a signal
        public virtual void change_source (Source s) throws NodeError {
            this.unset_source();
            if (this.val.type() != s.val.type()) {
                throw new NodeError.INCOMPATIBLE_SOURCETYPE(
                    "Can't connect. Source has type %s while Sink has type %s".printf(
                        s.val.type().name(), this.val.type().name()
                    )
                );
            }
            this.source = s;
            if (((Source) this.source).is_connected_to (this)) // FIXME This is a Sink not a Source - Change is_connected_to () to use a Dock not a Source?
                this.source.add_sink (this);
            this.connected(s);
        }

// FIXME: May on invalidate() you should release the source
// FIXME: Let this to implementators when source = null is called
        public virtual void unset_source () {
            if (((Sink) this.source).is_connected_to (this))
                this.source.remove_sink (this);
            Source s = this.source;
            this.source = null;
            this.invalidate ();
            this.disconnected (s);
        }

        /**
         * Checks if there is a source that supplies this sink with a value.
         * If yes, it returns that value. If not, returns the default value of
         * This Sink // FIXME May is not necesary to throw an error just return NULL
         */
        public virtual GLib.Value get_value() throws NodeError {
            if (this.source != null && this.valid) {
                return this.val;
            } else {
                throw new NodeError.NO_SOURCE("This sink has no source to drain data from");
            }
        }

        public virtual void change_value (GLib.Value v) throws NodeError {
            if (this.val.type() != v.type())
                throw new NodeError.INCOMPATIBLE_VALUE (
                    "Cannot feed a %s value into this %s Sink".printf(
                        v.type().name(),this.val.type().name())
                );
            this.val = v;
            // FIXME: This properly is read-only then may let implementators to define how "Change a Value"
            //this.valid = true;
            this.changed ();
        }
    }
}
