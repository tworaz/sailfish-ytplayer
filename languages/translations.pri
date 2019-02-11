# Copyright (c) 2015 Piotr Tworek. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE.YTPlayer file.

TRANSLATIONS += \
    languages/ca.ts \
    languages/cs_CZ.ts \
    languages/de.ts \
    languages/el.ts \
    languages/en_GB.ts \
    languages/es.ts \
    languages/fi_FI.ts \
    languages/fr_FR.ts \
    languages/hu_HU.ts \
    languages/it_IT.ts \
    languages/ja.ts \
    languages/nl_NL.ts \
    languages/pl_PL.ts \
    languages/pt_BR.ts \
    languages/ru_RU.ts \
    languages/sv.ts \
    languages/tr.ts \
    languages/zh_CN.ts \
    languages/zh_TW.ts

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
