#include "YTUpdateWorker.h"

YTUpdateWorker::YTUpdateWorker() : QObject()
{

}

void YTUpdateWorker::refreshLocal() {
    QFile ytdl(QStandardPaths::writableLocation(QStandardPaths::DataLocation)+QDir::separator()+"youtube-dl");
    if(ytdl.exists()) {
        QProcess process;
        QStringList args;
        args.append(QString(QStandardPaths::writableLocation(QStandardPaths::DataLocation)+QDir::separator()+"youtube-dl"));
        args.append(QString("--version"));

        process.start(python, args, QIODevice::ReadOnly);
        process.waitForFinished();

        if (process.exitStatus() == QProcess::NormalExit &&
            process.exitCode() == 0) {
            localVersion = QString(process.readAllStandardOutput());
            localVersion = localVersion.trimmed();
            qDebug() << "New local version:" << localVersion;
        }
    }
    else {
        qDebug() << "Local version not installed";
        localVersion = "0000.00.00";
    }
    emit localRefreshComplete(localVersion);
    return;
}

void YTUpdateWorker::refreshRemote() {
    QProcess process;
    QStringList args;
    args.append(QString("-L"));
    args.append(QString("http://yt-dl.org/"));

    process.start(curl, args, QIODevice::ReadOnly);
    process.waitForFinished();

    if(process.exitStatus() == QProcess::NormalExit &&
        process.exitCode() == 0) {
        remoteVersion = QString(process.readAllStandardOutput());
        remoteVersion = remoteVersion.section("(v",1,1).section(")",0,0);
    }

    // If the string could not be parsed,
    // no network connection etc.
    if(remoteVersion.length() < 10 || remoteVersion.length() > 20) {
        qDebug() << "Error checking remote version";
        remoteVersion = "----.--.--";
    }

    qDebug() << "New remote version found:" << remoteVersion;
    emit remoteRefreshComplete(remoteVersion);
    return;
}

void YTUpdateWorker::installUpdate() {
    QProcess process;
    QStringList args;
    args.append(QString("-L"));
    args.append(QString("https://yt-dl.org/downloads/latest/youtube-dl"));
    args.append(QString("-o"));
    args.append(QString(QStandardPaths::writableLocation(QStandardPaths::DataLocation)+QDir::separator()+"youtube-dl"));

    process.start(curl, args, QIODevice::ReadOnly);
    process.waitForFinished();

    if (process.exitStatus() == QProcess::NormalExit &&
        process.exitCode() == 0) {
        refreshLocal();
        YTVideoUrlFetcher::runInitialCheck();
    }
    emit updateComplete();
    return;
}
