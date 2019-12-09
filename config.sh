#!/bin/bash

function build_libs() {
    local wkdir_path="$(pwd)"
    export NUMCORES=`grep -c ^processor /proc/cpuinfo`
    if [ ! -n "$NUMCORES" ]; then
      export NUMCORES=`sysctl -n hw.ncpu`
    fi
    echo Using $NUMCORES cores

    if [ -z "$IS_OSX" ]; then
        activate_ccache

        cd "$wkdir_path"
        pcre_dir="./cache/pcre"
        mkdir -p "$pcre_dir"
        pcre_ver=8.38
        curl -L -O https://ftp.pcre.org/pub/pcre/pcre-$pcre_ver.tar.gz
        tar xf pcre-$pcre_ver.tar.gz -C "$pcre_dir" --strip-components 1
        cd "$pcre_dir" \
            && ./configure \
            && make -j${NUMCORES} \
            && make install \
            && ldconfig 2>&1 || true

        cd "$wkdir_path"
        swig_dir="./cache/swig"
        mkdir -p "$swig_dir"
        swig_ver=4.0.1
        curl -L -O http://downloads.sourceforge.net/project/swig/swig/swig-$swig_ver/swig-$swig_ver.tar.gz
        tar xf swig-$swig_ver.tar.gz -C "$swig_dir" --strip-components 1
        cd "$swig_dir" \
            && ./configure --without-perl5 --without-tcl --without-java \
                --without-ruby --without-javascript --without-lua \
                --with-python=/opt/python/cp27/bin/python \
                --with-python3=/opt/python/cp37/bin/python \
            && make -j${NUMCORES} \
            && make install \
            && ldconfig 2>&1 || true

    else
        brew install ccache swig
        export PATH="/usr/local/opt/ccache/libexec:$PATH"

    fi

    cd "$wkdir_path"
}

function build_wheel {
    build_libs
    build_bdist_wheel $@
}

function run_tests {
    cd ..
    local wkdir_path="$(pwd)"
    echo Running tests at root path: ${wkdir_path}
    cd ${wkdir_path}/py_slvs
    # pytest
    python -c 'import py_slvs'
}

