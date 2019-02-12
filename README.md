YTPlayer
=======

YTPlayer is an unofficial YouTube client for SailfishOS.

<div class="row">
<img width="240px" src="https://github.com/direc85/harbour-ytplayer/raw/master/artwork/screenshots/VirtualBox_Sailfish%20OS%20Emulator_02_12_2018_00_53_48.png" />
<img width="240px" src="https://github.com/direc85/harbour-ytplayer/raw/master/artwork/screenshots/VirtualBox_Sailfish%20OS%20Emulator_12_02_2019_15_00_00.png" />
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

Translating
-----------

If you want to translate YTPlayer into your native language you can use Transifex (https://www.transifex.com/tworaz/ytplayer).
