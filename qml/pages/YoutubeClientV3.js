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

var _youtube_data_v3_url = "https://www.googleapis.com/youtube/v3/";

var VIDEO_RANKING_LIKE = "like"
var VIDEO_RANKING_DISLIKE = "dislike"
var VIDEO_RANKING_NONE = "none"

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
            "&maxResults=" + Prefs.get("ResultsPerPage");

    for (var key in queryParams) {
        if (queryParams.hasOwnProperty(key)) {
            url += "&" + key + "=" + queryParams[key];
        }
    }
    return url;
}


function _getAuthHeader() {
    return Prefs.get("YouTubeAccessTokenType") + " " +
           Prefs.get("YouTubeAccessToken");
}


function _asyncFormPost(url, content, onSuccess, onFailure)
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
    xhr.open("POST", url);
    xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
    xhr.setRequestHeader('Content-Length', content.length);
    if (Prefs.isAuthEnabled()) {
        xhr.setRequestHeader("Authorization", _getAuthHeader());
    }
    xhr.send(content);
}


function _refreshOAuthToken(onSuccess, onFailure)
{
    var body = "client_id=" + NativeUtil.YouTubeAuthData["client_id"] +
            "&client_secret=" + NativeUtil.YouTubeAuthData["client_secret"] +
            "&refresh_token=" + Prefs.get("YouTubeRefreshToken") +
            "&grant_type=refresh_token";

    _asyncFormPost(NativeUtil.YouTubeAuthData["token_uri"], body,
        function(response) {
            Log.debug("Token refresh succeeded");
            Prefs.set("YouTubeAccessToken", response.access_token);
            Prefs.set("YouTubeAccessTokenType", response.token_type);
            onSuccess(response);
        }, function(error) {
            onFailure(error);
        });
}


function _xhr_onreadystate(xhr, onSuccess, onFailure, onRetry)
{
    if (xhr.readyState === XMLHttpRequest.DONE) {
        if (xhr.status === 200) {
            var response = JSON.parse(xhr.responseText);
            onSuccess(response);
        } else if (xhr.status === 204) {
            onSuccess();
        } else if (xhr.status === 401 && Prefs.isAuthEnabled()) {
            Log.debug("Refreshing OAuth2 token");
            _refreshOAuthToken(function (response) {
                if (onRetry) {
                    onRetry();
                } else {
                    _asyncJsonRequest(xhr._url, onSuccess, onFailure);
                }
            }, function (error) {
                onFailure(error);
            });
        } else {
            var details = xhr.responseText ? JSON.parse(xhr.responseText) : undefined;
            onFailure({ "code" : xhr.status, "details" : details });
        }
    }
}


function _asyncJsonRequest(url, onSuccess, onFailure, method)
{
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        _xhr_onreadystate(xhr, onSuccess, onFailure);
    }
    if (method) {
        xhr.open(method, url);
    } else {
        xhr.open("GET", url);
    }
    xhr._url = url;
    if (Prefs.isAuthEnabled()) {
        xhr.setRequestHeader("Authorization", _getAuthHeader());
    }
    xhr.send();
}


function requestOAuthTokens(authCode, onSuccess, onFailure) {
    var content = "code=" + authCode +
            "&client_id=" + NativeUtil.YouTubeAuthData["client_id"] +
            "&client_secret=" + NativeUtil.YouTubeAuthData["client_secret"] +
            "&redirect_uri=urn:ietf:wg:oauth:2.0:oob" +
            "&grant_type=authorization_code";

    _asyncFormPost(NativeUtil.YouTubeAuthData["token_uri"],
                   content, onSuccess, onFailure);
}


function getVideoCategories(onSuccess, onFailure)
{
    var url = _getYoutubeV3Url("videoCategories", {"part" : "snippet"});

    _asyncJsonRequest(url, function (result) {
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
    var url = _getYoutubeV3Url("videos", {
        "part"            : "snippet",
        "chart"           : "mostPopular",
        "videoCategoryId" : categoryId,
    });

    if (pageToken !== undefined) {
        url += "&pageToken=" + pageToken;
    }

    _asyncJsonRequest(url, function(result) {
        console.assert(result.kind === "youtube#videoListResponse");
        console.assert(result.hasOwnProperty('items') && result.items.length > 0);
        console.assert(result.items[0].kind === "youtube#video");
        onSuccess(result)
    }, onFailure);
}


function getVideosInPlaylist(playlistId, onSuccess, onFailure, pageToken)
{
    var url = _getYoutubeV3Url("playlistItems", {
        "part"       : "snippet",
        "playlistId" : playlistId
    });

    if (pageToken !== undefined) {
        url += "&pageToken=" + pageToken;
    }

    _asyncJsonRequest(url, function(response) {
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

    _asyncJsonRequest(url, function(response) {
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

    _asyncJsonRequest(url, function(response) {
        console.assert(response.kind === "youtube#channelListResponse");
        console.assert(response.items.length === 1);
        console.assert(response.items[0].kind ==="youtube#channel");
        onSuccess(response);
    }, onFailure);
}


function getSubscriptions(onSuccess, onFailure, pageToken)
{
    var url = _getYoutubeV3Url("subscriptions", {
        "part" : "id", "mine" : true, "part" : "snippet" });

    if (pageToken !== undefined) {
        url += "&pageToken=" + pageToken;
    }

    _asyncJsonRequest(url, function(response) {
        console.assert(response.kind === "youtube#subscriptionListResponse")
        onSuccess(response);
    }, onFailure);
}


function subscribeChannel(channelId, onSuccess, onFailure)
{
    var url = _youtube_data_v3_url + "subscriptions?part=snippet";

    var resource = JSON.stringify ({
        "snippet" : {
            "resourceId" : {
                "kind" : "youtube#channel",
                "channelId" : channelId,
            }
        }
    });

    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        _xhr_onreadystate(xhr, function(response) {
            console.assert(response.kind === "youtube#subscription");
            onSuccess(response);
        }, onFailure, function() {
            subscribeChannel(channelId, onSuccess, onFailure);
        });
    }
    xhr.open("POST", url);
    xhr.setRequestHeader("Authorization", _getAuthHeader());
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.setRequestHeader('Content-Length', resource.length);
    xhr.send(resource);
}


function unsubscribe(subscriptionId, onSuccess, onFailure)
{
    var url = _youtube_data_v3_url + "subscriptions?id=" + subscriptionId;

    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        _xhr_onreadystate(xhr, onSuccess, onFailure, function() {
            unsubscribe(subscriptionId, onSuccess, onFailure);
        });
    }
    xhr.open("DELETE", url);
    xhr.setRequestHeader("Authorization", _getAuthHeader());
    xhr.send();
}


function isChannelSubscribed(channelId, onSuccess, onFailure)
{
    var _successHandler = function (response) {
        for (var i = 0; i < response.items.length; ++i) {
            var item = response.items[i];
            console.assert(item.snippet.resourceId.kind === "youtube#channel");
            if (item.snippet.resourceId.channelId === channelId) {
                console.assert(item.kind === "youtube#subscription");
                onSuccess(item);
                return;
            }
        }
        if (response.hasOwnProperty('nextPageToken')) {
            getSubscriptions(_successHandler, onFailure, response.nextPageToken);
        }
        onSuccess(undefined);
    };

    getSubscriptions(_successHandler, onFailure);
}


function isVideoLiked(videoId, onSuccess, onFailure)
{
    var url = _getYoutubeV3Url("videos/getRating", { "id" : videoId });

    _asyncJsonRequest(url, function(response) {
        console.assert(response.kind === "youtube#videoGetRatingResponse")
        console.assert(response.items.length === 1)
        console.assert(response.items[0].videoId === videoId)
        onSuccess(response.items[0]);
    }, onFailure);
}


function rankVideo(videoId, rating, onSuccess, onFailure)
{
    var url = _youtube_data_v3_url + "videos/rate?id=" + videoId + "&rating=" + rating;

    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        _xhr_onreadystate(xhr, function(response) {
            console.assert(response === undefined);
            onSuccess();
        }, onFailure);
    }
    xhr.open("POST", url);
    xhr.setRequestHeader("Authorization", _getAuthHeader());
    xhr.send();
}


function getVideosForRanking(rank, onSuccess, onFailure, pageToken)
{
    var opts = {
        "part"     : "snippet",
        "myRating" : rank,
    };
    if (pageToken) {
        opts.pageToken = pageToken
    }

    var url = _getYoutubeV3Url("videos", opts)

    _asyncJsonRequest(url, function(response) {
        console.assert(response.kind === "youtube#videoListResponse");
        onSuccess(response);
    }, onFailure);
}


function getSearchResults(query, onSuccess, onFailure, pageToken)
{
    var qParams = {
        "q"    : query,
        "part" : "snippet",
        "type" : "video,channel",
    };

    var safeSearchValue = undefined;
    switch (parseInt(Prefs.get(Prefs.SafeSearch))) {
    default:
        Log.warn("Unknown safe search value: " + Prefs.get(Prefs.SafeSearch));
        break;
    case 0:
        qParams.safeSearch = "none";
        break;
    case 1:
        qParams.safeSearch = "moderate";
        break;
    case 2:
        qParams.safeSearch = "strict";
        break;
    }

    if (pageToken) {
        qParams.pageToken = pageToken;
    }

    var url = _getYoutubeV3Url("search", qParams);

    _asyncJsonRequest(url, function(response) {
        console.assert(response.kind === "youtube#searchListResponse");
        if (response.items.length > 0) {
            console.assert(response.items[0].kind === "youtube#searchResult");
        }
        onSuccess(response);
    }, onFailure);
}


function search(parameters, onSuccess, onFailure)
{
    var url = _getYoutubeV3Url("search", parameters);

    _asyncJsonRequest(url, function(response) {
        console.assert(response.kind === "youtube#searchListResponse");
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

            //Log.debug("Stream map string: " + stream_map_str );

            var stream_map_array = [];
            tokens = stream_map_str.split(',');
            for (var i = 0; i < tokens.length; i++) {
                //Log.debug("Stream map array element " + i);
                var map_elements = tokens[i].split('&');
                var map = {};
                for (var k = 0; k < map_elements.length; k++) {
                    var map_entry = map_elements[k].split('=');
                    if (map_entry[0] === 'url') {
                        map[map_entry[0]] = decodeURIComponent(map_entry[1]);
                    } else {
                        map[map_entry[0]] = map_entry[1];
                    }
                    //Log.debug("  " + map_entry[0] + " = " + map[map_entry[0]]);
                }
                stream_map_array[i] = map;
            }

            //Log.debug(JSON.stringify(stream_map_array, undefined, 2));

            var selected_url = undefined;
            for (var i = 0; i < stream_map_array.length; i++) {
                if (stream_map_array[i].itag === "18") {
                    if ("s" in stream_map_array[i]) {
                        //TODO: support playing videos with encrypted signatures
                        Log.info("Encrypted signature detected, can't play video directly, falling back to ytapi.com");
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
