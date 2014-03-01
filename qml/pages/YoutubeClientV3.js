/*-
 * Copyright (c) 2014 Peter Tworek
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the author nor the names of any co-contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

.import "Settings.js" as Settings

var _youtube_data_v3_url = "https://www.googleapis.com/youtube/v3/";

function getYoutubeV3Url(reference, queryParams)
{
    var locale = Qt.locale().name;
    if (locale === "C") {
        locale = "en_US";
    }

    var url =  _youtube_data_v3_url + reference +
            "?regionCode=" + NativeUtil.regionCode +
            "&key=" + NativeUtil.YouTubeDataKey +
            "&hl=" + locale;

    for (var key in queryParams) {
        if (queryParams.hasOwnProperty(key)) {
            url += "&" + key + "=" + queryParams[key];
        }
    }
    return url;
}

function getVideoCategories(result, onSuccess, onFailure)
{
    var url = getYoutubeV3Url("videoCategories", {"part" : "snippet"});

    console.debug("XHR: " + url);

    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status == 200) {
                var items = JSON.parse(xhr.responseText)["items"];
                for (var i = 0; i < items.length; i++) {
                    var category = items[i];
                    if (category.snippet.assignable) {
                        result.append(category);
                    }
                }
                onSuccess();
            } else {
                onFailure({"code" : xhr.status, "details" : JSON.parse(xhr.responseText)});
            }
        }
    }
    xhr.open("GET", url);
    xhr.send();
}

function getVideosInCategory(categoryId, onSuccess, onFailure, pageToken)
{
    var resultsPerPage = Settings.get(Settings.RESULTS_PER_PAGE);
    var qParams = {};

    qParams["part"] = "snippet";
    qParams["maxResults"] = resultsPerPage;
    qParams["chart"] = "mostPopular";
    qParams["videoCategoryId"] = categoryId;

    var url = getYoutubeV3Url("videos", qParams);

    if (pageToken !== undefined) {
        url += "&pageToken=" + pageToken;
    }

    console.debug("XHR: " + url);

    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status == 200) {
                onSuccess(JSON.parse(xhr.responseText));
            } else {
                onFailure({"code" : xhr.status, "details" : JSON.parse(xhr.responseText)});
            }
        }
    }
    xhr.open("GET", url);
    xhr.send();
}

function getVideoDetails(videoId, onSuccess, onFailure)
{
    var url = getYoutubeV3Url("videos", {"part" : "contentDetails, snippet",
                              "id" : videoId});

    console.debug("XHR: " + url);

    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status !== 200) {
                onFailure({"code" : xhr.status, "details" : JSON.parse(xhr.responseText)});
                return;
            }
            var details = JSON.parse(xhr.responseText);
            onSuccess(details.items[0]);
        }
    }
    xhr.open("GET", url);
    xhr.send();
}

function getSearchResults(query, onSuccess, onFailure, pageToken)
{
    var qParams = {};
    qParams["q"] = query;
    qParams["part"] = "snippet";
    qParams["maxResults"] = Settings.get(Settings.RESULTS_PER_PAGE);
    //TODO: Only search for videos until browsing channels and playlist is implemented
    qParams["type"] = "video";
    if (pageToken) {
        qParams["pageToken"] = pageToken;
    }

    var url = getYoutubeV3Url("search", qParams);

    console.debug("XHR: " + url);

    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if (xhr.readyState == XMLHttpRequest.DONE) {
            if (xhr.status !== 200) {
                onFailure({"code" : xhr.status, "details" : JSON.parse(xhr.responseText)});
                return;
            }
            var response = JSON.parse(xhr.responseText);
            onSuccess(response);
        }
    }
    xhr.open("GET", url);
    xhr.send();
}

function getVideoUrl(videoId, onSuccess, onFailure)
{
    var req = "http://www.youtube.com/get_video_info?video_id=" + videoId +
            "&el=player_embedded&gl=US&hl=en&eurl=https://youtube.googleapis.com/v/&asf=3&sts=1588";

    console.debug("XHR: " + req);

    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status !== 200) {
                onFailure({"code" : xhr.status, "details" : JSON.parse(xhr.responseText)});
                return;
            }
            var stream_map_str = undefined;
            var tokens = xhr.responseText.split("&");
            for (var i = 0; i < tokens.length; i++) {
                var pair = tokens[i].split("=");
                if (pair[0] === "url_encoded_fmt_stream_map") {
                    stream_map_str = decodeURIComponent(pair[1]);
                    break;
                }
            }

            if (stream_map_str === undefined) {
                onFailure({"code" : 0, "details" : "No video streams found!"});
                return;
            }

            //console.debug("Stream map string: " + stream_map_str );

            var stream_map_array = [];
            tokens = stream_map_str.split(',');
            for (var i = 0; i < tokens.length; i++) {
                //console.debug("Stream map array element " + i);
                var map_elements = tokens[i].split('&');
                var map = {};
                for (var k = 0; k < map_elements.length; k++) {
                    var map_entry = map_elements[k].split('=');
                    if (map_entry[0] === 'url') {
                        map[map_entry[0]] = decodeURIComponent(map_entry[1]);
                    } else {
                        map[map_entry[0]] = map_entry[1];
                    }
                    //console.debug("  " + map_entry[0] + " = " + map[map_entry[0]]);
                }
                stream_map_array[i] = map;
            }

            //console.debug(JSON.stringify(stream_map_array, undefined, 2));

            var selected_url = undefined;
            for (var i = 0; i < stream_map_array.length; i++) {
                if (stream_map_array[i].itag === "18") {
                    if ("sig" in stream_map_array[i]) {
                        selected_url = stream_map_array[i].url +
                                "&signature=" + stream_map_array[i].sig;
                    } else {
                        // Encrypted content not supported directly
                        console.log("No support for playing videos with encrypted signatures from youtube directly," +
                                    "falling back to ytapi.com");
                        selected_url = getVideoUrlYtAPI(videoId, 18);
                    }

                    break;
                }
            }

            if (selected_url === undefined) {
                onFailure({"code" : 0, "details" : "No 360p video stream found!"});
                return;
            }

            onSuccess(selected_url);
        }
    }
    xhr.open("GET", req);
    xhr.send();
}

function getVideoUrlYtAPI(videoId, itag)
{
    return "http://ytapi.com/?vid=" + videoId + "&format=direct&itag=" + itag;
}
