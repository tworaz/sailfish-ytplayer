// Copyright (c) 2014-2015 Piotr Tworek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE.YTPlayer file.

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../common"

Page {
    id: page
    objectName: "SettingsPage"
    allowedOrientations: Orientation.All

    onStatusChanged: {
        if (status === PageStatus.Active) {
            accountSwitch.checked = YTPrefs.isAuthEnabled()
            requestCoverPage("Default.qml")
        }
    }

    // Update-related properties
    property string localVersion: YTUpdater.localVersion
    property string remoteVersion: YTUpdater.remoteVersion
    property bool updating: YTUpdater.updating
    property bool updateButtonClicked: false

    // Update check helper; just for convenience
    function updateMenuItem(itemEnabled, spinnerEnabled, newText) {
        updateYtdlButton.text = newText
        updateYtdlButton.enabled = itemEnabled
        updateYtdlIndicator.running = spinnerEnabled

    }

    // Phase 1: Check the local version
    function startUpdate() {
        //: Shown while checking for local version of youtube-dl
        //% "Checking local version..."
        updateMenuItem(false, true, qsTrId("ytplayer-update-checking-local-version"))
        YTUpdater.checkLocalVersion()
    }

    // Phase 2: Check the remote version
    onLocalVersionChanged: {
        if(!updateButtonClicked || localVersion === "checkingLocalVersion")
            return;
        //: Shown while checking for remote version of youtube-dl
        //% "Checking remote version..."
        updateMenuItem(false, true, qsTrId("ytplayer-update-checking-remote-version"))
        YTUpdater.checkRemoteVersion()
    }

    // Phase 3: Compare the versions, and update if needed, or stop here
    onRemoteVersionChanged: {
        if(!updateButtonClicked || remoteVersion === "checkingRemoteVersion")
            return;
        if(remoteVersion === "----.--.--")
            //: Shown when checking youtube-dl version from the Internet failed
            //% "Could not check for updates"
            updateMenuItem(true, false, qsTrId("ytplayer-update-checking-remote-version-failed"))
        else if(remoteVersion !== localVersion) {
            //: Shown while downloading the youtube-dl update from the Internet
            //% "Downloading youtube-dl..."
            updateMenuItem(false, true, qsTrId("ytplayer-update-downloading"))
            YTUpdater.startUpdate()
        }
        else
            //: Shown when youtube-dl is up to date and no update is needed
            //% "Youtube-dl is up to date"
            updateMenuItem(false, false, qsTrId("ytplayer-update-up-to-date"))
    }

    // Phase 4: Verify the updated version, or inform about failure
    onUpdatingChanged: {
        console.log("update done "+localVersion+remoteVersion)
        if(!updateButtonClicked)
            return;
        if(localVersion !== remoteVersion)
            //: Shown after youtube-dl update failed
            //% "Updating youtube-dl failed"
            updateMenuItem(false, false, qsTrId("ytplayer-update-failed"))
        else(localVersion === remoteVersion)
            //: Shown after youtube-dl update succeeded
            //% "Updated youtube-dl succesfully"
            updateMenuItem(false, false, qsTrId("ytplayer-update-successful"))
    }

    SilicaFlickable {
        anchors.fill: parent
        readonly property real _h: topColumn.height + bottomColumn.height
        contentHeight: height > _h ? height : _h

        PullDownMenu {
            MenuItem {
                //: Label for menu option showing application log viewer
                //% "View logs"
                text: qsTrId("ytplayer-action-view-logs")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("LogViewer.qml"))
                }
            }
        }

        Column {
            id: topColumn
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                //: Settings page title
                //% "Settings"
                title: qsTrId("ytplayer-title-settings")
            }

            TextSwitch {
                id: accountSwitch
                //: Label of switch activating/deactivating YouTube account integration
                //% "YouTube account integration"
                text: qsTrId("ytplayer-label-account-integration")
                //: Description of switch activating/deactivating YouTube account integration
                //% "Allow YTPlayer to manage YouTube user account."
                description: qsTrId("ytplayer-description-account-integration")
                automaticCheck: false
                checked: YTPrefs.isAuthEnabled()

                onClicked: {
                    if (YTPrefs.isAuthEnabled()) {
                        Log.info("Disabling account integration")
                        YTPrefs.disableAuth();
                        checked = false
                    } else {
                        Log.info("Enabling account integration")
                        pageStack.push(Qt.resolvedUrl("YTOAuth2.qml"))
                    }
                }
            }
        }

        Grid {
            id: bottomColumn
            width: parent.width
            columns: page.isPortrait ? 1 : 2
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.paddingLarge

            Item {
                height: updateYtdlButton.height
                width: parent.width / parent.columns
                SettingsButton {
                    id: updateYtdlButton
                    anchors.fill: parent
                    enabled: localVersion !== remoteVersion
                    //: MenuItem text for updating youtube-dl
                    //% "Update youtube-dl"
                    text: {
                        if(localVersion !== remoteVersion)
                            //: MenuItem text for updating youtube-dl
                            //% "Update youtube-dl"
                            return qsTrId("ytplayer-update-youtubedl")
                        else
                            qsTrId("ytplayer-update-up-to-date")
                    }
                    color: (root.highlighted | root.selected) ? Theme.highlightColor : (enabled ? Theme.primaryColor : Theme.secondaryColor)
                    onClicked: {
                        // We have to use this so that the
                        // functions do not fire at page activation
                        updateButtonClicked = true
                        startUpdate()
                    }
                }
                BusyIndicator {
                    id: updateYtdlIndicator
                    anchors.centerIn: parent
                    size: BusyIndicatorSize.Medium
                    running: false
                    visible: running
                }
            }
            SettingsButton {
                width: parent.width / parent.columns
                //: Label for menu option showing cache settings page
                //% "Cache"
                text: qsTrId("ytplayer-action-cache-settings")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("CacheSettings.qml"))
                }
            }
            SettingsButton {
                width: parent.width / parent.columns
                //: Label for menu option showing video download settings page
                //% "Download"
                text: qsTrId("ytplayer-action-download-settings")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("DownloadSettings.qml"))
                }
            }
            SettingsButton {
                width: parent.width / parent.columns
                //: Label for menu option showing application language settings page
                //% "Language"
                text: qsTrId("ytplayer-action-language-settings")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("LanguageSettings.qml"))
                }
            }
            SettingsButton {
                width: parent.width / parent.columns
                //: Label for menu option showing video player settings page
                //% "Player"
                text: qsTrId("ytplayer-action-player-settings")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("PlayerSettings.qml"))
                }
            }
            SettingsButton {
                width: parent.width / parent.columns
                //: Label for menu option showing search settings page
                //% "Search"
                text: qsTrId("ytplayer-action-search-settings")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("SearchSettings.qml"))
                }
            }
        } // Column

        VerticalScrollDecorator {}

    } // SilicaFlickable
}
