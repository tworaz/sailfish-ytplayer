#include "YTUpdater.h"

YTUpdater::YTUpdater(): QObject() {
    QTimer::singleShot(0, this, SLOT());

    ytThread = new QThread(this);
    //ytThread->setPriority(QThread::NormalPriority);

    ytWorker = new YTUpdateWorker();
    ytWorker->moveToThread(ytThread);

    ytThread->start();

    connect(ytWorker, SIGNAL(localRefreshComplete(QString)), this, SLOT(setLocalVersion(QString)));
    connect(ytWorker, SIGNAL(remoteRefreshComplete(QString)), this, SLOT(setRemoteVersion(QString)));
    connect(ytWorker, SIGNAL(updateComplete()), this, SLOT(updateComplete()));

    connect(this, SIGNAL(refreshLocal()), ytWorker, SLOT(refreshLocal()));
    connect(this, SIGNAL(refreshRemote()), ytWorker, SLOT(refreshRemote()));
    connect(this, SIGNAL(installUpdate()), ytWorker, SLOT(installUpdate()));

    return;
}

bool YTUpdater::isInstalled() {
    QFile ytdl(QStandardPaths::writableLocation(QStandardPaths::DataLocation)+QDir::separator()+"youtube-dl");
    return ytdl.exists();
}

void YTUpdater::setLocalVersion(QString newVersion) {
    localVersion = newVersion;
    emit localVersionChanged(newVersion);
    checking = false;
    emit checkingChanged(checking);
}

void YTUpdater::setRemoteVersion(QString newVersion) {
    remoteVersion = newVersion;
    emit remoteVersionChanged(newVersion);
    checking = false;
    emit checkingChanged(checking);
}

void YTUpdater::startUpdate() {
    emit installUpdate();
    updating = true;
    emit updatingChanged(updating);
    return;
}

void YTUpdater::updateComplete() {
    updating = false;
    emit updatingChanged(updating);
    return;
}


void YTUpdater::checkLocalVersion() {
    checking = true;
    emit checkingChanged(checking);
    localVersion = "checkingLocalVersion";
    emit localVersionChanged(localVersion);
    emit refreshLocal();
    return;
}

void YTUpdater::checkRemoteVersion() {
    checking = true;
    emit checkingChanged(checking);
    remoteVersion = "checkingRemoteVersion";
    emit remoteVersionChanged(remoteVersion);
    emit refreshRemote();
    return;
}
