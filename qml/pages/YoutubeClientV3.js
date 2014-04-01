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


function _getYoutubeV3Url(reference, queryParams)
{
    var locale = Qt.locale().name;
    if (locale === "C") {
        locale = "en_US";
    }

    var url =  _youtube_data_v3_url + reference +
            "?regionCode=" + regionCode +
            "&key=" + NativeUtil.YouTubeDataKey +
            "&hl=" + locale +
            "&maxResults=" + Settings.get(Settings.RESULTS_PER_PAGE);

    for (var key in queryParams) {
        if (queryParams.hasOwnProperty(key)) {
            url += "&" + key + "=" + queryParams[key];
        }
    }
    return url;
}


function _async_json_request(url, onSuccess, onFailure)
{
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                var response = JSON.parse(xhr.responseText);
                onSuccess(response);
            } else {
                var details = xhr.responseText ? JSON.parse(xhr.responseText) : undefined;
                onFailure({ "code" : xhr.status, "details" : details });
            }
        }
    }
    xhr.open("GET", url);
    xhr.send();
}


function requestOAuthTokens(authCode, onSuccess, onFailure) {
    var params = "code=" + authCode +
            "&client_id=" + NativeUtil.YouTubeAuthData["client_id"] +
            "&client_secret=" + NativeUtil.YouTubeAuthData["client_secret"] +
            "&redirect_uri=urn:ietf:wg:oauth:2.0:oob" +
            "&grant_type=authorization_code";

    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                var response = JSON.parse(xhr.responseText);
                onSuccess(response);
            } else {
                var details = xhr.responseText ? JSON.parse(xhr.responseText) : undefined;
                onFailure({ "code" : xhr.status, "details" : details });
            }
        }
    }
    xhr.open("POST", NativeUtil.YouTubeAuthData["token_uri"]);
    xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
    xhr.setRequestHeader('Content-Length', params.length);
    xhr.send(params);
}


function getVideoCategories(onSuccess, onFailure)
{
    var url = _getYoutubeV3Url("videoCategories", {"part" : "snippet"});

    _async_json_request(url, function (result) {
        console.assert(result.hasOwnProperty('kind') &&
                       result.kind === "youtube#videoCategoryListResponse");
        console.assert(result.hasOwnProperty('items') && result.items.length > 0);
        console.assert(result.items[0].hasOwnProperty('kind') &&
                       result.items[0].kind === "youtube#videoCategory");
        onSuccess(result.items);
    }, onFailure);
}


function getVideosInCategory(categoryId, onSuccess, onFailure, pageToken)
{
    var qParams = {};
    qParams["part"] = "snippet";
    qParams["chart"] = "mostPopular";
    qParams["videoCategoryId"] = categoryId;

    var url = _getYoutubeV3Url("videos", qParams);

    if (pageToken !== undefined) {
        url += "&pageToken=" + pageToken;
    }

    _async_json_request(url, function(result) {
        console.assert(result.kind === "youtube#videoListResponse");
        console.assert(result.hasOwnProperty('items') && result.items.length > 0);
        console.assert(result.items[0].kind === "youtube#video");
        onSuccess(result)
    }, onFailure);
}


function getVideosInPlaylist(playlistId, onSuccess, onFailure)
{
    var url = _getYoutubeV3Url("playlistItems",{"part" : "snippet", "playlistId" : playlistId});

    _async_json_request(url, function(response) {
        console.assert(response.kind === "youtube#playlistItemListResponse");
        console.assert(response.items.length > 0);
        console.assert(response.items[0].kind === "youtube#playlistItem");
        onSuccess(response);
    }, onFailure);
}


function getVideoDetails(videoId, onSuccess, onFailure)
{
    var url = _getYoutubeV3Url("videos", {"part" : "contentDetails, snippet, statistics",
                              "id" : videoId});

    _async_json_request(url, function(response) {
        console.assert(response.items.length === 1);
        console.assert(response.kind === "youtube#videoListResponse");
        console.assert(response.items[0].kind === "youtube#video");
        onSuccess(response.items[0]);
    }, onFailure);
}


function getChannelDetails(channelId, onSuccess, onFailure)
{
    var url = _getYoutubeV3Url("channels",
        {"part" : "snippet,statistics,contentDetails", "id" : channelId});

    _async_json_request(url, function(response) {
        console.assert(response.kind === "youtube#channelListResponse");
        console.assert(response.items.length === 1);
        console.assert(response.items[0].kind ==="youtube#channel");
        onSuccess(response);
    }, onFailure);
}


function getSearchResults(query, onSuccess, onFailure, pageToken)
{
    var qParams = {};
    qParams["q"] = query;
    qParams["part"] = "snippet";
    qParams["type"] = "video,channel";

    var safeSearchValue = undefined;
    switch (parseInt(Settings.get(Settings.SAFE_SEARCH))) {
    default:
        console.warn("Unknown safe search value: " + Settings.get(Settings.SAFE_SEARCH));
        break;
    case Settings.SAFE_SEARCH_NONE:
        qParams["safeSearch"] = "none";
        break;
    case Settings.SAFE_SEARCH_MODERATE:
        qParams["safeSearch"] = "moderate";
        break;
    case Settings.SAFE_SEARCH_STRICT:
        qParams["safeSearch"] = "strict";
        break;
    }

    if (pageToken) {
        qParams["pageToken"] = pageToken;
    }

    var url = _getYoutubeV3Url("search", qParams);

    _async_json_request(url, function(response) {
        console.assert(response.kind === "youtube#searchListResponse");
        if (response.items.length > 0) {
            console.assert(response.items[0].kind === "youtube#searchResult");
        }
        onSuccess(response);
    }, onFailure);
}


function getVideoUrl(videoId, onSuccess, onFailure)
{
    var req = "http://www.youtube.com/get_video_info?video_id=" + videoId +
            "&el=player_embedded&gl=US&hl=en&eurl=https://youtube.googleapis.com/v/&asf=3&sts=1588";

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
                    if ("s" in stream_map_array[i]) {
                        //TODO: support playing videos with encrypted signatures
                        console.log("Encrypted signature detected, can't play video directly, falling back to ytapi.com");
                        selected_url = getVideoUrlYtAPI(videoId, 18);
                    } else if ("sig" in stream_map_array[i]) {
                        selected_url = stream_map_array[i].url +
                                "&signature=" + stream_map_array[i].sig;
                    } else {
                        selected_url = stream_map_array[i].url;
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
