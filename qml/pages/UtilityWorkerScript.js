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

Qt.include("duration.js")

WorkerScript.onMessage = function(task)
{
    var response = undefined;
    if (task.name === "appendToModel") {
        appendToModel(task.model, task.data);
    } else if (task.name === "appendCategoryToModel") {
        appendCategoryToModel(task.model, task.data);
    } else if (task.name === "parseDuration") {
        response = parseDuration(task.value);
    } else {
        console.error("Unknown task type: " + JSON.stringify(task, undefined, 2));
    }
    WorkerScript.sendMessage(response);
}

function appendToModel(model, data)
{
    for (var i = 0; i < data.length; ++i) {
        model.append(data[i]);
    }
    model.sync();
}

function appendCategoryToModel(model, data)
{
    for (var i = 0; i < data.length; ++i) {
        if (data[i].snippet.assignable) {
            model.append(data[i]);
        }
    }
    model.sync();
}

function parseDuration(value)
{
    var d = new Duration(value);
    return d.asClock();
}
