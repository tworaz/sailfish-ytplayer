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

function parseDuration(dur) {
    var seconds = Math.ceil(dur / 1000)
    var hours = Math.floor(seconds / 3600)
    seconds -= hours * 3600
    var minutes = Math.floor(seconds / 60)
    seconds -= minutes * 60

    var date = new Date()
    date.setHours(hours)
    date.setMinutes(minutes)
    date.setSeconds(seconds)

    if (hours > 0) {
        return Qt.formatTime(date, "hh:mm:ss")
    } else if (minutes > 0) {
        return Qt.formatTime(date, "mm:ss")
    } else {
        return Qt.formatTime(date, "m:ss")
    }
}

function getYouTubeIconForCategoryId(category)
{
    var categoryId = parseInt(category);
    switch (categoryId) {
    case 1:  return "\ue64d"  // Film & Animation
    case 2:  return "\ue650"  // Autos & Vechicles
    case 10: return "\ue636"  // Music
    case 15: return "\ue633"  // Pets & Animals
    case 17: return "\ue60d"  // Sports
    case 19: return "\ue641"  // Travel & Events
    case 20: return "\ue64f"  // Gaming
    case 22: return "\ue634"  // People & Blogs
    case 23: return "\ue638"  // Commedy
    case 24: return "\ue64c"  // Entertainment
    case 25: return "\ue634"  // News & Politics
    case 26: return "\ue639"  // Howto & Style
    case 27: return "\ue64b"  // Education
    case 28: return "\ue610"  // Science & Technology
    case 29: return "\ue64e"  // Nonprofits & Activism
    default:
        console.debug("No icon for category: " + category)
        return "\ue60c"
    }
}
