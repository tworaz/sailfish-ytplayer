TRANSLATIONS += \
        languages/en.ts \
        languages/de.ts \
        languages/ru.ts
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
