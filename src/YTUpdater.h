#ifndef YTUPDATER_H
#define YTUPDATER_H

#include <QObject>
#include <QStandardPaths>
#include <QThread>
#include <QProcess>
#include <QDir>
#include <QDebug>
#include <QTimer>
#include "YTUpdateWorker.h"

class YTUpdater: public QObject
{
    Q_OBJECT

public:
    YTUpdater();

    Q_PROPERTY(QString localVersion READ getLocalVersion NOTIFY localVersionChanged)
    Q_PROPERTY(QString remoteVersion READ getRemoteVersion NOTIFY remoteVersionChanged)
    Q_PROPERTY(bool checking READ isChecking NOTIFY checkingChanged)
    Q_PROPERTY(bool updating READ isUpdating NOTIFY updatingChanged)

    Q_INVOKABLE void startUpdate();
    Q_INVOKABLE void checkLocalVersion();
    Q_INVOKABLE void checkRemoteVersion();
    Q_INVOKABLE bool isInstalled();

    QString getLocalVersion()  { return localVersion; }
    QString getRemoteVersion() { return remoteVersion; }
    bool isUpdating()          { return updating; }
    bool isChecking()          { return checking; }

private:

    // These must be non-identical strings,
    // and not "----.--.--"
    QString localVersion = "localVersion";
    QString remoteVersion = "remoteVersion";

    bool updating = false;
    bool checking = false;

    YTUpdateWorker *ytWorker;
    QThread *ytThread;

    QString curl = "/usr/bin/curl";
    QString python = "/usr/bin/python3";

    QThread* GetNewThread();

private slots:
    void setLocalVersion(QString newVersion);
    void setRemoteVersion(QString newVersion);
    void updateComplete();

signals:
    void localVersionChanged(QString newVersion);
    void remoteVersionChanged(QString newVersion);
    void updatingChanged(bool status);
    void checkingChanged(bool status);

    void refreshLocal();
    void refreshRemote();
    void installUpdate();
};

#endif // YTUPDATER_H
