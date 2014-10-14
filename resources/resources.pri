RESOURCES += resources/misc.qrc

# mobile county code json target
mcc_data.target = mcc-data
mcc_data.commands = \
    $$top_srcdir/scripts/mcc-data-util.py \
            --keyfile=$$top_srcdir/youtube-data-api-v3.key \
            --mccfile=$$top_srcdir/resources/mcc-data.json \
            --verbose --mode check

QMAKE_EXTRA_TARGETS += mcc-data
PRE_TARGETDEPS += mcc-data

