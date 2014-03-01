/*
 *The MIT License (MIT)
 *Copyright (c) 2013 Evan W. Isnor
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in the
 * Software without restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so, subject to the
 * following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 * PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
 * ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/*
 * Downloaded from: https://github.com/leadhead9/durationjs
 */

/**
 * @constructor
 */
var Duration = function(representation) {
	/* Fields */
	this.seconds = 0;

	/* Constructor */
	if (representation == 'undefined' || representation == undefined || representation == '') {
		representation = 0;
	}

	if (typeof representation === 'number' && representation < 0) {
		throw new Error(Duration.prototype.Error.NegativeValue);
	}
	else if (typeof representation === 'number') {
		this.seconds = representation;
	}
	else {
		var isSupportedFormat = false;
		for (var format in Duration.prototype.DurationFormat) {
			var pattern = Duration.prototype.DurationFormat[format].pattern;
			var parser = Duration.prototype.DurationFormat[format].parser;
			if (pattern.test(representation)) {
				isSupportedFormat = true;
				this.seconds = parser(this.seconds, representation.match(pattern));
				break;
			}
		}

		if (!isSupportedFormat) {
			throw new Error(Duration.prototype.Error.UnexpectedFormat);
		}
	}

	if (isNaN(this.seconds)) {
		throw new Error(Duration.prototype.Error.Overflow);
	}
}

/* Calendar values */

Duration.prototype.Calendar = {
	Seconds : {
		per : {
			Minute : 60,
			Hour : 60 * 60,
			Day : 60 * 60 * 24,
			Week : 60 * 60 * 24 * 7,
			Month : 60 * 60 * 24 * 30.4368,
			Year : 60 * 60 * 24 * 365.242
		}
	},
	Minutes : {
		per : {
			Hour : 60,
			Day : 60 * 24,
			Week : 60 * 24 * 7,
			Month : 60 * 24 * 30.4368,
			Year : 60 * 24 * 365.242
		}
	},
	Hours : {
		per : {
			Day : 24,
			Week : 24 * 7,
			Month : 24 * 30.4368,
			Year : 24 * 365.242
		}
	},
	Days : {
		per : {
			Week : 7,
			Month : 30.4368,
			Year : 365.242
		}
	},
	Weeks : {
        per : {
			Month : 4.34812,
			Year : 52.1775
		}
	},
	Months : {
		per : {
			Year : 12
		}
	}
}

/* Error Messages */

Duration.prototype.Error = {}

Duration.prototype.Error.UnexpectedFormat = "Unexpected duration format. Refer to ISO 8601.";

Duration.prototype.Error.NegativeValue = "Cannot create a negative duration.";

Duration.prototype.Error.Overflow = "Cannot represent a duration that large. Float overflow.";

/* Parsing */

Duration.prototype.Parser = {}

Duration.prototype.Parser.Extended = function(seconds, match) {
	var cal = Duration.prototype.Calendar;

	for (var groupIndex = 1; groupIndex < match.length; groupIndex++) {
		var value = parseInt(match[groupIndex], 10);
		if (groupIndex === 1) {
			seconds += value * cal.Seconds.per.Year;
		}
		else if (groupIndex === 2) {
			if (value >= 12) {
				throw new Error(Duration.prototype.Error.UnexpectedFormat);
			}
			seconds += value * cal.Seconds.per.Month;
		}
		else if (groupIndex === 3) {
			if (value > 31) {
				throw new Error(Duration.prototype.Error.UnexpectedFormat);
			}
			seconds += value * cal.Seconds.per.Day;
		}
		else if (groupIndex === 4) {
			if (value >= 24) {
				throw new Error(Duration.prototype.Error.UnexpectedFormat);
			}
			seconds += value * cal.Seconds.per.Hour;
		}
		else if (groupIndex === 5) {
			if (value >= 60) {
				throw new Error(Duration.prototype.Error.UnexpectedFormat);
			}
			seconds += value * cal.Seconds.per.Minute;
		}
		else if (groupIndex === 6) {
			if (value >= 60) {
				throw new Error(Duration.prototype.Error.UnexpectedFormat);
			}
			seconds += value;
		}
	}
	return seconds;
}

Duration.prototype.Parser.Basic = Duration.prototype.Parser.Extended;

Duration.prototype.Parser.StandardWeeks = function(seconds, match) {
	var cal = Duration.prototype.Calendar;

	for (var i = 1; i < match.length; i++) {
		var value = match[i];
		if (/\d+W/.test(value)) {
			seconds += parseInt(value.replace('W', ''), 10) * cal.Seconds.per.Week;
		}
		else if (/\d+[A-Z]/.test(value)) {
			throw new Error(Duration.prototype.Error.UnexpectedFormat);
		}
	}
	return seconds;
}

Duration.prototype.Parser.Standard = function(seconds, match) {
	var cal = Duration.prototype.Calendar;

	if (match[0] === 'P' || match[0] === 'PT') {
		throw new Error(Duration.prototype.Error.UnexpectedFormat);
	}

	var hasFoundT = false;
	for (var groupIndex = 1; groupIndex < match.length; groupIndex++) {
		var value = match[groupIndex];
		if (/T/.test(value)) {
			hasFoundT = true;
		}
		else if (/\d+Y/.test(value)) {
			seconds += parseInt(value.replace('Y', ''), 10) * cal.Seconds.per.Year;
		}
		else if (/\d+M/.test(value) && !hasFoundT) {
			seconds += parseInt(value.replace('M', ''), 10) * cal.Seconds.per.Month;
		}
		else if (/\d+D/.test(value)) {
			seconds += parseInt(value.replace('D', ''), 10) * cal.Seconds.per.Day;
		}
		else if (/\d+H/.test(value)) {
			seconds += parseInt(value.replace('H', ''), 10) * cal.Seconds.per.Hour;
		}
		else if (/\d+M/.test(value) && hasFoundT) {
			seconds += parseInt(value.replace('M', ''), 10) * cal.Seconds.per.Minute;
		}
		else if (/\d+S/.test(value)) {
			seconds += parseInt(value.replace('S', ''), 10);
		}
		else if (/\d+[A-Z]/.test(value)) {
			throw new Error(Duration.prototype.Error.UnexpectedFormat);
		}
	}
	return seconds;
}

Duration.prototype.DurationFormat = {
	Extended : {
		pattern : /^P(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})$/,
		parser : Duration.prototype.Parser.Extended
	},
	Basic : {
		pattern : /^P(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})$/,
		parser : Duration.prototype.Parser.Basic
	},
	StandardWeeks : {
		pattern : /^P(\d+W)$/,
		parser : Duration.prototype.Parser.StandardWeeks
	},
	Standard : {
		pattern : /^P(\d+Y)*(\d+M)*(\d+D)*(?:(T)(\d+H)*(\d+M)*(\d+S)*)?$/,
		parser : Duration.prototype.Parser.Standard
	}
}

/*
Pad a value with leading zeros by specifying the desired length of the result string.
	Example: padInt(2, 4) will return '0002'
*/
Duration.prototype.padInt = function(value, length) {
	var valString = value + '';
	var result = '';

	var c = 0;
	for (var i = 0; i < length; i++) {
		if (length - i <= valString.length) {
			result += valString[c++];
		}
		else {
			result += '0';
		}
	}

	return result;
}

/* Cumulative getters */

Duration.prototype.inSeconds = function() {
	return this.seconds;
}

Duration.prototype.inMinutes = function() {
	return this.seconds / this.Calendar.Seconds.per.Minute;
}

Duration.prototype.inHours = function() {
	return this.seconds / this.Calendar.Seconds.per.Hour;
}

Duration.prototype.inDays = function() {
	return this.seconds / this.Calendar.Seconds.per.Day;
}

Duration.prototype.inWeeks = function() {
	return this.seconds / this.Calendar.Seconds.per.Week;
}

Duration.prototype.inMonths = function() {
	return this.seconds / this.Calendar.Seconds.per.Month;
}

Duration.prototype.inYears = function() {
	return this.seconds / this.Calendar.Seconds.per.Year;
}

/* Arithmetic */

Duration.prototype.add = function(other) {
	return new Duration(this.seconds + other.seconds);
}

Duration.prototype.subtract = function(other) {
	return new Duration(this.seconds - other.seconds);
}

/* Formatted getters */

/*
Returns an object that represents the full duration with integer values.
*/
Duration.prototype.value = function() {
	var result = {};
	result.years = Math.floor(this.seconds / this.Calendar.Seconds.per.Year);
	result.months = Math.floor((this.seconds - (result.years * this.Calendar.Seconds.per.Year)) / this.Calendar.Seconds.per.Month);
	result.days = Math.floor((this.seconds - (result.years * this.Calendar.Seconds.per.Year)
					- (result.months * this.Calendar.Seconds.per.Month)) / this.Calendar.Seconds.per.Day);
	result.hours = Math.floor((this.seconds - (result.years * this.Calendar.Seconds.per.Year)
					- (result.months * this.Calendar.Seconds.per.Month)
					- (result.days * this.Calendar.Seconds.per.Day)) / this.Calendar.Seconds.per.Hour);
	result.minutes = Math.floor((this.seconds - (result.years * this.Calendar.Seconds.per.Year)
					- (result.months * this.Calendar.Seconds.per.Month)
					- (result.days * this.Calendar.Seconds.per.Day)
					- (result.hours * this.Calendar.Seconds.per.Hour)) / this.Calendar.Seconds.per.Minute);
	result.seconds = Math.round((this.seconds - (result.years * this.Calendar.Seconds.per.Year)
					- (result.months * this.Calendar.Seconds.per.Month)
					- (result.days * this.Calendar.Seconds.per.Day)
					- (result.hours * this.Calendar.Seconds.per.Hour)
					- (result.minutes * this.Calendar.Seconds.per.Minute)));
	return result;
}

Duration.prototype.ago = function() {
	if (this.seconds == 0) {
		return 'just now';
	}
	else if (this.seconds < this.Calendar.Seconds.per.Minute) {
		return this.seconds + ' second' + ((this.seconds > 1) ? 's' : '') + ' ago';
	}
	else if (this.seconds < this.Calendar.Seconds.per.Hour) {
		return Math.floor(this.inMinutes()) + ' minute' + ((this.inMinutes() > 1) ? 's' : '') + ' ago';
	}
	else if (this.seconds < this.Calendar.Seconds.per.Day) {
		return Math.floor(this.inHours()) + ' hour' + ((this.inHours() > 1) ? 's' : '') + ' ago';
	}
	else if (this.seconds < this.Calendar.Seconds.per.Week) {
		return Math.floor(this.inDays()) + ' day' + ((this.inDays() > 1) ? 's' : '') + ' ago';
	}
	else if (this.seconds < this.Calendar.Seconds.per.Month) {
		return Math.floor(this.inWeeks()) + ' week' + ((this.inWeeks() > 1) ? 's' : '') + ' ago';
	}
	else if (this.seconds < this.Calendar.Seconds.per.Year) {
		return Math.floor(this.inMonths()) + ' month' + ((this.inMonths() > 1) ? 's' : '') + ' ago';
	}
	else {
		return Math.floor(this.inYears()) + ' year' + ((this.inYears() > 1) ? 's' : '') + ' ago';
	}
}

Duration.prototype.asClock = function() {
	var duration = this.value();
	if (duration.hours == 0) {
		return duration.minutes + ':'
			+ ((duration.seconds < 10) ? '0' + duration.seconds : duration.seconds);
	}
	else {
		return duration.hours + ':'
			+ ((duration.minutes < 10) ? '0' + duration.minutes : duration.minutes) + ':'
			+ ((duration.seconds < 10) ? '0' + duration.seconds : duration.seconds);
	}
}

Duration.prototype.asStandard = function() {
	var duration = this.value();
	if (this.seconds == 0) {
		return 'PT0S';
	}

	var shouldHaveT = duration.hours > 0 || duration.minutes > 0 || duration.seconds > 0;

	return 'P' + ((duration.years > 0) ? duration.years + 'Y' : '')
			+ ((duration.months > 0) ? duration.months + 'M' : '')
			+ ((duration.days > 0) ? duration.days + 'D' : '')
			+ ((shouldHaveT) ? 'T' : '')
			+ ((duration.hours > 0) ? duration.hours + 'H' : '')
			+ ((duration.minutes > 0) ? duration.minutes + 'M' : '')
			+ ((duration.seconds > 0) ? duration.seconds + 'S' : '');
}

Duration.prototype.asStandardWeeks = function() {
	return 'P' + Math.floor(this.inWeeks()) + 'W';
}

Duration.prototype.asExtended = function() {
	var duration = this.value();
	return 'P' + this.padInt(duration.years, 4) + '-'
			+ this.padInt(duration.months, 2) + '-'
			+ this.padInt(duration.days, 2) + 'T'
			+ this.padInt(duration.hours, 2) + ':'
			+ this.padInt(duration.minutes, 2) + ':'
			+ this.padInt(duration.seconds, 2);
}

Duration.prototype.asBasic = function() {
	var duration = this.value();
	return 'P' + this.padInt(duration.years, 4)
			+ this.padInt(duration.months, 2)
			+ this.padInt(duration.days, 2) + 'T'
			+ this.padInt(duration.hours, 2)
			+ this.padInt(duration.minutes, 2)
			+ this.padInt(duration.seconds, 2);
}
