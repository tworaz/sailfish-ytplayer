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

import QtQuick 2.0

Item {
    property var _taskQueue: []

    function appendToModel(model, data, done) {
        _taskQueue.push({
            "name"  : "appendToModel",
            "model" : model,
            "data"  : data,
            "done"  : done,
        })
        worker.process()
    }

    function appendCategoryToModel(model, data, done) {
        _taskQueue.push({
            "name"  : "appendCategoryToModel",
            "model" : model,
            "data"  : data,
            "done"  : done,
        })
        worker.process()
    }

    function parseDuration(value, done) {
        _taskQueue.push({
            "name"  : "parseDuration",
            "value" : value,
            "done"  : done,
        })
        worker.process()
    }

    function parseStreamsInfo(info, done) {
        _taskQueue.push({
            "name" : "parseStreamsInfo",
            "data" : info,
            "done" : done,
        })
        worker.process()
    }

    WorkerScript {
        id: worker
        source: "UtilityWorkerScript.js"

        property bool busy: false
        property var task: undefined

        function process() {
            if (!busy && _taskQueue.length > 0) {
                task = _taskQueue.pop()
                busy = true
                Log.debug("Scheduling task: " + task.name)
                sendMessage(task)
            }
        }

        onMessage: {
            if (task.done) {
                task.done(messageObject)
            }
            task = undefined
            busy = false
            process()
        }
    }
}
