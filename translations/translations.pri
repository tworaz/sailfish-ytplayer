# Copyright (c) 2015 Piotr Tworek. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE.YTPlayer file.

TRANSLATIONS += \
    translations/ca.ts \
    translations/cs_CZ.ts \
    translations/de.ts \
    translations/el.ts \
    translations/en_GB.ts \
    translations/es.ts \
    translations/fi_FI.ts \
    translations/fr_FR.ts \
    translations/hu_HU.ts \
    translations/it_IT.ts \
    translations/ja.ts \
    translations/nl_NL.ts \
    translations/pl_PL.ts \
    translations/pt_BR.ts \
    translations/ru_RU.ts \
    translations/sv.ts \
    translations/tr.ts \
    translations/zh_CN.ts \
    translations/zh_TW.ts

OTHER_FILES += translations/translations.json

updateqm.input = TRANSLATIONS
updateqm.output = $$top_builddir/translations/${QMAKE_FILE_BASE}.qm
updateqm.commands = \
        lrelease -idbased ${QMAKE_FILE_IN} \
        -qm $$top_builddir/translations/${QMAKE_FILE_BASE}.qm
updateqm.CONFIG += no_link
QMAKE_EXTRA_COMPILERS += updateqm

PRE_TARGETDEPS += compiler_updateqm_make_all

localization.files = $$files($$top_builddir/translations/*.qm)
localization.path = /usr/share/$${TARGET}/translations

INSTALLS += localization
