cmake_minimum_required (VERSION 2.6)
project(libgtkflow C)

SET(VERSION "0.1")

list(APPEND CMAKE_MODULE_PATH
    ${CMAKE_SOURCE_DIR}/cmake/vala
)

include(ValaPrecompile)
include(ValaVersion)

find_package(Vala REQUIRED)
ensure_vala_version("0.26" MINIMUM)
find_program(VALADOC_EXEC valadoc)

find_package(PkgConfig)

pkg_check_modules(GLIB REQUIRED glib-2.0)
add_definitions(${GLIB_CFLAGS} ${GLIB_CFLAGS_OTHER})
link_libraries(${GLIB_LIBRARIES})
link_directories(${GLIB_LIBRARY_DIRS})

pkg_check_modules(GTK gtk+-3.0)
add_definitions(${GTK_CFLAGS} ${GTK_CFLAGS_OTHER})
link_libraries(${GTK_LIBRARIES})
link_directories(${GTK_LIBRARY_DIRS})

vala_precompile(VALA_LIB_C
    "libgtkflow/dummy.vala"
    "libgtkflow/node.vala"
    "libgtkflow/nodeview.vala"
    "libgtkflow/dock.vala"
    "libgtkflow/source.vala"
    "libgtkflow/sink.vala"
PACKAGES
    gtk+-3.0
OPTIONS
    --thread
    --target-glib 2.32
    --library=gtkflow
    -H include/gtkflow.h
    --gir=GtkFlow-${VERSION}.gir
)

add_custom_target(docs
    COMMAND
        ${VALADOC_EXEC} -o doc --package-name=gtkflow --pkg gtk+-3.0
            libgtkflow/*.vala
    COMMENT
        "Generating documentation"
)

add_definitions(-fstack-protector-all -D_FORTIFY_SOURCE=2 -fPIC)
add_definitions(-w)

add_library("gtkflow" SHARED ${VALA_LIB_C})  

add_custom_target(typelib ALL
    COMMAND
        g-ir-compiler --shared-library=libgtkflow.so GtkFlow-${VERSION}.gir
                      -o GtkFlow-${VERSION}.typelib
    DEPENDS
        "gtkflow"
    COMMENT
        "Creating typelib"
)

add_custom_target(testing
    DEPENDS
        gtkflow
    COMMAND
        ./test/run_tests.sh
    COMMENT
        "Running Unittests"
)

install(FILES "include/gtkflow.h" DESTINATION include )
install(FILES GtkFlow-${VERSION}.typelib DESTINATION lib/girepository-1.0)
install(FILES data/gtkflow.pc DESTINATION lib/pkgconfig)
install(TARGETS "gtkflow"
    LIBRARY DESTINATION lib
)

