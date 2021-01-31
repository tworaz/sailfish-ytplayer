#include "YTUpdateWorker.h"

YTUpdateWorker::YTUpdateWorker() : QObject()
{
    logger = &YTLogger::instance();
}

void YTUpdateWorker::refreshLocal() {
    QFile ytdl("/usr/share/harbour-ytplayer/youtube-dl/youtube-dl");
    if(ytdl.exists()) {
        QProcess process;
        QStringList args;
        args.append("/usr/share/harbour-ytplayer/youtube-dl/youtube-dl");
        args.append(QString("--version"));

        process.start(python, args, QIODevice::ReadOnly);
        process.waitForFinished();

        if (process.exitStatus() == QProcess::NormalExit &&
            process.exitCode() == 0) {
            localVersion = QString(process.readAllStandardOutput());
            localVersion = localVersion.trimmed();
            logger->info(QString("youtube-dl " +localVersion+ " is installed"));
            YTVideoUrlFetcher::setVersion(localVersion, true);
        }
    }
    else {
        logger->warn(QString("youtube-dl is not installed"));
        localVersion = "0000.00.00";
        YTVideoUrlFetcher::setVersion(localVersion, false);
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
        logger->info(QString("youtube-dl " + remoteVersion + " is available for download"));
    }
    else {
        logger->error(QString("Could not download youtube-dl update information"));
    }

    // If the string could not be parsed,
    // no network connection etc.
    if(remoteVersion.length() < 10 || remoteVersion.length() > 20) {
        logger->error(QString("Could not parse youtube-dl update information"));
        remoteVersion = "----.--.--";
    }

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
        logger->info("youtube-dl updated successfully");
        refreshLocal();
        YTVideoUrlFetcher::runInitialCheck();
    }
    else {
        logger->error("youtube-dl update failed");
    }
    emit updateComplete();
    return;
}
