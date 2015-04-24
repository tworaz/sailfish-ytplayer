# Copyright (c) 2015 Piotr Tworek. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE.YTPlayer file.

!exists(nemo-qml-plugin-notifications/notifications.pro): \
    error(Some git submodules are missing, please run \
          \'git submodule update --init\' in toplevel directory)

_SRC = $$PWD/nemo-qml-plugin-notifications/src
_NOTIFICATIONS_XML_FILE = $$_SRC/org.freedesktop.Notifications.xml

!exists($$top_builddir/notificationmanagerproxy.cpp) {
    system(cd $$_SRC && \
           qdbusxml2cpp org.freedesktop.Notifications.xml \
               -p $$top_builddir/notificationmanagerproxy \
               -c NotificationManagerProxy \
               -i notification.h)
}

HEADERS += \
        $$_SRC/notification.h \
        $$top_builddir/notificationmanagerproxy.h

SOURCES += \
        $$_SRC/notification.cpp \
        $$top_builddir/notificationmanagerproxy.cpp

INCLUDEPATH += $$_SRC
