-include $(top_srcdir)/git.mk

# Empty variable to be added elements later
CLEANFILES=
BUILT_SOURCES=
AM_VALAFLAGS=

### Library

# Library to create
lib_LTLIBRARIES = libgtkflow-0.2.la

# Vala source code
sources = \
	namespace-info.vala \
	dock.vala \
	node.vala \
	nodeview.vala \
	sink.vala \
	source.vala


### General Compilation flags
AM_CPPFLAGS = \
	-include $(CONFIG_HEADER) \
	-DPACKAGE_DATA_DIR=\""$(datadir)"\" \
	-DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
	-DPACKAGE_SRC_DIR=\""$(srcdir)"\" \
	-DG_LOG_DOMAIN=\"libgtkflow\" \
	-I$(top_srcdir) \
	$(NULL)

AM_CFLAGS = \
	-g \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(VALA_CFLAGS) \
	$(GTK_CFLAGS) \
	$(NULL)

# -Wall   # TODO: add this back when we can properly handle more libxml2/vala warnings

if DEBUG
  AM_VALAFLAGS += \
    -D DEBUG \
    --enable-mem-profiler \
    -g
endif


# library flags
AM_VALAFLAGS += \
	$(ERROR_VALAFLAGS) \
	--library=gtkflow-0.2 \
	--vapidir=. \
	--pkg gee-0.8 \
	--pkg glib-2.0 \
	--pkg gtk+-3.0 \
	--includedir libgtkflow \
	--vapi gtkflow-0.2.vapi \
	-H gtkflow.h \
	-C \
	$(NULL)

libgtkflow_0_2_la_LIBADD = \
	$(GEE_LIBS) \
	$(GLIB_LIBS) \
	$(VALA_LIBS) \
	$(GTK_LIBS) \
	$(NULL)

libgtkflow_0_2_la_LDFLAGS = \
	-version-info "$(LT_CURRENT)":"$(LT_REVISION)":"$(LT_AGE)"

$(sources:.vala=.c): $(sources)
	$(VALAC) $(AM_VALAFLAGS) $^

libgtkflow_0_2_la_SOURCES= \
  $(sources:.vala=.c)


# .h header file
gtkflow.h: libgtkflow-0.2.la
gtkflowdir= $(includedir)/gtkflow-$(API_VERSION)/libgtkflow
gtkflow_HEADERS = gtkflow.h

# .vapi Vala API file
gtkflow-0.2.vapi: libgtkflow-0.2.la
vapidir = $(datadir)/vala/vapi
dist_vapi_DATA = \
	gtkflow-0.2.vapi \
	gtkflow-0.2.deps \
	$(NULL)

# .pc pkg-config file
pkgconfig_in = gtkflow-0.2.pc.in
pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = $(pkgconfig_in:.in=)

EXTRA_DIST = \
	$(sources) \
	$(pkgconfig_in) \
	$(NULL)

GITIGNOREFILES = \
	$(sources:.vala=.c) \
	libgtkflow_0_2_la_vala.stamp \
	$(NULL)


BUILT_SOURCES += \
	gtkflow.h \
	gtkflow-0.2.vapi \
	$(NULL)


# This makes GObject Introspection optional and requires to use --enable-instrospection switch on configure
if HAVE_INTROSPECTION

### GObject Introspection
# dlname:
#   Extract our dlname like libfolks does, see bgo#658002 and bgo#585116
#   This is what g-ir-scanner does.
libgtkflow_dlname = \
        `$(SED) -n "s/^dlname='\([A-Za-z0-9.+-]\+\)'/\1/p" libgtkflow-0.2.la`


AM_VALAFLAGS += \
	--gir=GtkFlow-$(API_VERSION).gir

INTROSPECTION_GIRS = GtkFlow-$(API_VERSION).gir
INTROSPECTION_COMPILER_ARGS = --includedir=. -l $(libgtkflow_dlname)

GtkFlow-0.2.gir: libgtkflow-0.2.la

GtkFlow-0.2.typelib: $(INTROSPECTION_GIRS)
	$(INTROSPECTION_COMPILER) $(INTROSPECTION_COMPILER_ARGS)  $< -o $@

girdir = $(INTROSPECTION_GIRDIR)
gir_DATA = $(INTROSPECTION_GIRS)
typelibdir = $(INTROSPECTION_TYPELIBDIR)
typelib_DATA = GtkFlow-0.2.typelib
CLEANFILES += $(gir_DATA) $(typelib_DATA)

endif

if PLATFORM_WIN32
AM_VALAFLAGS += \
	--symbols=gtkflow.symbols

libgtkflow_0_2_la_LDFLAGS += -shared -o libgtkflow-0.2.dll -no-undefined \
	-out-imlib -export-all-symbols -output-def

gtkflow.symbols: libgtkflow-0.2.la

libgtkflow-0.2.def: gtkflow.symbols
	(echo -e EXPRTS; $(CPP) -P $(DEF_FLAGS) \
	- <$^ | sed -e '/^$$/d' -e 's/^/ /' -e 's/G_GNUC_[^ ]*//g' \
	| sort) > gtkflow.def.tmp && mv gtkflow.def.tmp libgtkflow-0.2.def

libgtkflow-0.2.def: libgtkflow-0.2.la
libgtkflowdefdir=$(libdir)
libgtkflowdef_DATA=libgtkflow-0.2.def

CLEANFILES += \
	gtkflow.symbols \
	libgtkflow-0.2.def

BUILT_SOURCES += \
	libgtkflow-0.2.def

endif

CLEANFILES += \
	$(pkgconfig_DATA) \
	namespace-info.vala \
	$(sources:.vala=.c) \
	gtkflow-0.2.vapi \
	gtkflow.h

