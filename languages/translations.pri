# Copyright (c) 2015 Piotr Tworek. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE.YTPlayer file.

TRANSLATIONS += \
        languages/cs_CZ.ts \
        languages/de.ts \
        languages/en_GB.ts \
        languages/nl_NL.ts \
        languages/ru_RU.ts \
        languages/sv.ts

OTHER_FILES += languages/translations.json

updateqm.input = TRANSLATIONS
updateqm.output = $$top_builddir/languages/${QMAKE_FILE_BASE}.qm
updateqm.commands = \
	lrelease -idbased ${QMAKE_FILE_IN} \
        -qm $$top_builddir/languages/${QMAKE_FILE_BASE}.qm
updateqm.CONFIG += no_link
QMAKE_EXTRA_COMPILERS += updateqm

PRE_TARGETDEPS += compiler_updateqm_make_all

localization.files = $$files($$top_builddir/languages/*.qm)
localization.path = /usr/share/$${TARGET}/languages

INSTALLS += localization
