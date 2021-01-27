YTPlayer
=======

YTPlayer is an unofficial YouTube client for SailfishOS.

<div class="row">
<img width="240px" src="https://github.com/direc85/harbour-ytplayer/raw/master/artwork/screenshots/VirtualBox_Sailfish%20OS%20Emulator_02_12_2018_00_53_48.png" />
&nbsp;
<img width="240px" src="https://github.com/direc85/harbour-ytplayer/raw/master/artwork/screenshots/VirtualBox_Sailfish%20OS%20Emulator_12_02_2019_15_00_00.png" />
&nbsp;
<img width="240px" src="https://github.com/direc85/harbour-ytplayer/raw/master/artwork/screenshots/VirtualBox_Sailfish%20OS%20Emulator_12_02_2019_15_00_45.png" />
</div>

Getting the source
------------------

Since YTPlayer uses some extra 3rd party components shipped in git submodules it needs to be cloned with --recursive option. Ex:

- git clone --recursive https://github.com/direc85/sailfish-ytplayer.git

Build Prequisites
-----------------

- SailfishOS SDK (https://sailfishos.org/develop/sdk-overview/)
- YouTube Data API v3 key & client ID (https://developers.google.com/youtube/v3/)

Building
--------

1. Paste your YouTube Data API v3 key into a file called youtube-data-api-v3.key and
   place it in the YTPlayer source directory.
2. Copy YouTube client ID JSON file into YTPlayer source directory. Rename the file to
   youtube-client-id.json
3. Start the SailfishOS SDK.
4. Load harbour-ytplayer.pro file.
5. Build and deploy the application to your phone/tablet/emulator.

If translations don't work, try the following:

1. Select i486/armv7hl > Release > Deploy as ARM package
2. Build > Clean project "harbour-ytplayer"
3. Build > Build project "harbour-ytplayer" (or click the hammer icon)
4. Build > Deploy project "harbour-ytplayer" (or click the play icon)

Translating
-----------

If you would like to create a new translation for YTPlayer, this is roughly how it's done:
- Fork the project
- Copy translations/en_GB.ts file to your language (e.g. no.ts for Norwgian)
- Add the new file to translations/translations.pri files TRANSLATIONS section accordingly
- Translate the new file
  - Qt Linguist comes with Sailfish Application SDK
  - Your generic UTF-8 capable text editor will work, too
- Test the translation
- Commit the changes
- Make a pull request

Or you can avoid forking by just creating a new issue and attach the new translated .ts file in the issue.
