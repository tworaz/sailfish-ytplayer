#ifndef YTUPDATEWORKER_H
#define YTUPDATEWORKER_H

#include <QObject>
#include <QProcess>
#include <QTimer>
#include <QStandardPaths>
#include <QDir>
#include <QDebug>
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
    QString curl = "/usr/bin/curl";
    QString python = "/usr/bin/python3";
    QString localVersion = "----.--.--";
    QString remoteVersion = "----.--.--";

signals:
    void updateComplete();
    void localRefreshComplete(QString localVersion);
    void remoteRefreshComplete(QString remoteVersion);
};

#endif // YTUPDATEWORKER_H
