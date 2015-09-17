# Copyright (c) 2015 Piotr Tworek. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE.YTPlayer file.

_SRC = $$PWD/youtube-dl
_BUILD_DIR = $$top_builddir/build-ytdl
_PYTHON='$$LITERAL_HASH!/usr/bin/env python3'

ytdl.target = youtube-dl
ytdl.commands = \
    cd $$_SRC && \
    touch README.txt youtube-dl.1 youtube-dl.fish youtube-dl.bash-completion && \
    python3 setup.py build_py --quiet --compile -O2 --build-lib $$_BUILD_DIR && \
    cd $$_BUILD_DIR && \
    find youtube_dl -type f -name '*.pyo' -delete && \
    zip --quiet -r youtube-dl youtube_dl/ && \
    zip --quiet --junk-paths youtube-dl youtube_dl/__main__.py && \
    echo \\"$$_PYTHON\\" > youtube-dl && \
    cat youtube-dl.zip >> youtube-dl && \
    chmod +x youtube-dl; \
    rm -f youtube-dl.zip
ytdl.depends = $$_SRC/youtube_dl/version.py

QMAKE_EXTRA_TARGETS += ytdl
PRE_TARGETDEPS += youtube-dl

ytdl.files = $$files($$_BUILD_DIR/youtube-dl)
ytdl.path = /usr/share/$${TARGET}/bin

INSTALLS += ytdl
