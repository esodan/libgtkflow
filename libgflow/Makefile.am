-include $(top_srcdir)/git.mk

# Empty variable to be added elements later
CLEANFILES=
BUILT_SOURCES=
AM_VALAFLAGS=

### Library

# Library to create
lib_LTLIBRARIES = libgflow-0.2.la

# Vala source code
sources = \
	namespace-info.vala \
	gflow-dock.vala \
	gflow-node.vala \
	gflow-simple-sink.vala \
	gflow-simple-source.vala \
	gflow-sink.vala \
	gflow-source.vala


### General Compilation flags
AM_CPPFLAGS = \
	-include $(CONFIG_HEADER) \
	-DPACKAGE_DATA_DIR=\""$(datadir)"\" \
	-DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
	-DPACKAGE_SRC_DIR=\""$(srcdir)"\" \
	-DG_LOG_DOMAIN=\"libgflow\" \
	-I$(top_srcdir) \
	$(NULL)

AM_CFLAGS = \
	-g \
	$(GLIB_CFLAGS) \
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
	--library=gflow-0.2 \
	--vapidir=. \
	--pkg glib-2.0 \
	--pkg gtk+-3.0 \
	--includedir libgflow \
	--vapi gflow-0.2.vapi \
	-H gflow.h \
	-C \
	$(NULL)

libgflow_0_2_la_LIBADD = \
	$(GLIB_LIBS) \
	$(VALA_LIBS) \
	$(GTK_LIBS) \
	$(NULL)

libgflow_0_2_la_LDFLAGS = \
	-version-info "$(LT_CURRENT)":"$(LT_REVISION)":"$(LT_AGE)"

$(sources:.vala=.c): $(sources)
	$(VALAC) $(AM_VALAFLAGS) $^

libgflow_0_2_la_SOURCES= \
  $(sources:.vala=.c)


# .h header file
gflow.h: libgflow-0.2.la
gflowdir= $(includedir)/gflow-$(API_VERSION)/libgflow
gflow_HEADERS = gflow.h

# .vapi Vala API file
gflow-0.2.vapi: libgflow-0.2.la
vapidir = $(datadir)/vala/vapi
dist_vapi_DATA = \
	gflow-0.2.vapi \
	gflow-0.2.deps \
	$(NULL)

# .pc pkg-config file
pkgconfig_in = gflow-0.2.pc.in
pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = $(pkgconfig_in:.in=)

EXTRA_DIST = \
	$(sources) \
	$(pkgconfig_in) \
	$(NULL)

GITIGNOREFILES = \
	$(sources:.vala=.c) \
	libgflow_0_2_la_vala.stamp \
	$(NULL)


BUILT_SOURCES += \
	gflow.h \
	gflow-0.2.vapi \
	$(NULL)


# This makes GObject Introspection optional and requires to use --enable-instrospection switch on configure
if HAVE_INTROSPECTION

### GObject Introspection
# dlname:
#   Extract our dlname like libfolks does, see bgo#658002 and bgo#585116
#   This is what g-ir-scanner does.
libgflow_dlname = \
        `$(SED) -n "s/^dlname='\([A-Za-z0-9.+-]\+\)'/\1/p" libgflow-0.2.la`


AM_VALAFLAGS += \
	--gir=GFlow-$(API_VERSION).gir

INTROSPECTION_GIRS = GFlow-$(API_VERSION).gir
INTROSPECTION_COMPILER_ARGS = --includedir=. -l $(libgflow_dlname)

GFlow-0.2.gir: libgflow-0.2.la

GFlow-0.2.typelib: $(INTROSPECTION_GIRS)
	$(INTROSPECTION_COMPILER) $(INTROSPECTION_COMPILER_ARGS)  $< -o $@

girdir = $(INTROSPECTION_GIRDIR)
gir_DATA = $(INTROSPECTION_GIRS)
typelibdir = $(INTROSPECTION_TYPELIBDIR)
typelib_DATA = GFlow-0.2.typelib
CLEANFILES += $(gir_DATA) $(typelib_DATA)

endif

if PLATFORM_WIN32
AM_VALAFLAGS += \
	--symbols=gflow.symbols

libgflow_0_2_la_LDFLAGS += -shared -o libgflow-0.2.dll -no-undefined \
	-out-imlib -export-all-symbols -output-def

gflow.symbols: libgflow-0.2.la

libgflow-0.2.def: gflow.symbols
	(echo -e EXPRTS; $(CPP) -P $(DEF_FLAGS) \
	- <$^ | sed -e '/^$$/d' -e 's/^/ /' -e 's/G_GNUC_[^ ]*//g' \
	| sort) > gflow.def.tmp && mv gflow.def.tmp libgflow-0.2.def

libgflow-0.2.def: libgflow-0.2.la
libgflowdefdir=$(libdir)
libgflowdef_DATA=libgflow-0.2.def

CLEANFILES += \
	gflow.symbols \
	libgflow-0.2.def

BUILT_SOURCES += \
	libgflow-0.2.def

endif

CLEANFILES += \
	$(pkgconfig_DATA) \
	namespace-info.vala \
	$(sources:.vala=.c) \
	gflow-0.2.vapi \
	gflow.h

