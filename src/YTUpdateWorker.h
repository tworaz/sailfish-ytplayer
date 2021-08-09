#ifndef YTUPDATEWORKER_H
#define YTUPDATEWORKER_H

#include <QObject>
#include <QProcess>
#include <QTimer>
#include <QStandardPaths>
#include <QDir>
#include <QDebug>
#include "YTLogger.h"
#include "YTVideoUrlFetcher.h"

class YTUpdateWorker : public QObject
{
    Q_OBJECT
public:
    YTUpdateWorker();

public slots:
    void refreshLocal();
    void refreshRemote();
    void installUpdate();

private:
    const QString curl = "/usr/bin/curl";
    const QString python = "/usr/bin/python3";
    const QString ytdlFilename = QStandardPaths::writableLocation(QStandardPaths::DataLocation)+QDir::separator()+"youtube-dl";
    QString localVersion = "----.--.--";
    QString remoteVersion = "----.--.--";
    YTLogger* logger;

signals:
    void updateComplete();
    void localRefreshComplete(QString localVersion);
    void remoteRefreshComplete(QString remoteVersion);
};

#endif // YTUPDATEWORKER_H
