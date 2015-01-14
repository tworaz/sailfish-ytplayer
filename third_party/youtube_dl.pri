_SRC = $$PWD/youtube-dl
_BUILD_DIR = $$top_builddir/build-ytdl
_PYTHON='$$LITERAL_HASH!/usr/bin/env python'

ytdl.target = youtube-dl
ytdl.commands = \
    cd $$_SRC && \
    touch README.txt youtube-dl.1 youtube-dl.fish youtube-dl.bash-completion && \
    python setup.py build_py --quiet --compile -O2 --build-lib $$_BUILD_DIR && \
    cd $$_BUILD_DIR && \
    zip --quiet youtube-dl youtube_dl/*.pyo youtube_dl/*/*.pyo && \
    zip --quiet --junk-paths youtube-dl youtube_dl/__main__.pyo && \
    echo \\"$$_PYTHON\\" > youtube-dl && \
    cat youtube-dl.zip >> youtube-dl && \
    chmod +x youtube-dl && \
    rm youtube-dl.zip
ytdl.depends = $$_SRC/youtube_dl/version.py

QMAKE_EXTRA_TARGETS += ytdl
PRE_TARGETDEPS += youtube-dl

ytdl.files = $$files($$_BUILD_DIR/youtube-dl)
ytdl.path = /usr/share/$${TARGET}/bin

INSTALLS += ytdl
