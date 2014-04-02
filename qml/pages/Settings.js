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

.import QtQuick.LocalStorage 2.0 as Sql

var RESULTS_PER_PAGE = "results-per-page";
var SAFE_SEARCH = "safe-search"
var YOUTUBE_ACCOUNT_INTEGRATION = "youtube_account_integration"
var YOUTUBE_ACCESS_TOKEN_TYPE = "access_token_type"
var YOUTUBE_ACCESS_TOKEN = "access_token"
var YOUTUBE_REFRESH_TOKEN = "refresh_token"

var SAFE_SEARCH_NONE = 0;
var SAFE_SEARCH_MODERATE = 1;
var SAFE_SEARCH_STRICT = 2;

var ENABLE = "enable";
var DISABLE = "disable";

function _getDatabase()
{
    return Sql.LocalStorage.openDatabaseSync("YTPlayer", "1", "SettingsDatabase", 100000);
}

function _setDefaultValue(transaction, key, value) {
    transaction.executeSql('INSERT OR IGNORE INTO settings VALUES (?,?);', [key, value]);
}

function initialize()
{
    var db = _getDatabase();
    db.transaction(function(tx) {
        tx.executeSql('CREATE TABLE IF NOT EXISTS settings(key TEXT unique, value TEXT)');
        _setDefaultValue(tx, RESULTS_PER_PAGE, 20);
        _setDefaultValue(tx, SAFE_SEARCH, SAFE_SEARCH_MODERATE);
        _setDefaultValue(tx, YOUTUBE_ACCOUNT_INTEGRATION, DISABLE);
    });
}

function set(key, value)
{
    var db = _getDatabase();
    var retval = false;
    db.transaction(function (tx) {
        var res = tx.executeSql('INSERT OR REPLACE INTO settings VALUES(?,?);', [key, value]);
        if (res.rowsAffected > 0) {
            retval = true;
        } else {
            retval = false;
        }
    });
    return retval;
}

function get(key)
{
    var db = _getDatabase();
    var retval = undefined;
    db.transaction(function (tx) {
        var res = tx.executeSql('SELECT value FROM settings WHERE key=?;', [key]);
        if (res.rows.length > 0) {
            retval = res.rows.item(0).value;
        } else {
            retval = undefined;
        }
    });
    return retval;
}
