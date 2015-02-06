#!/usr/bin/env python2

import httplib, urllib, json
import sys, os, getopt, re

verbose = False

def show_help():
	print ("%s [options]\n" % sys.argv[0])
	print ("    --mode [check|generate], -m     Select mode (required)")
	print ("    --keyfile [file], -k            YouTube data API key file (required)")
	print ("    --mccfile [file], -c            Mobile Country code file path (required)")
	print ("    --verbose, -v                   Enable verbose log messages")
	print ("    --help, -h                      Show this help message")


def country_exists(country, mccData):
	for e in mccData:
		if e["gl"] == country["gl"]:
				return True
	return False


def error(msg):
		sys.stderr.write("[ERROR] " + msg + "\n")

def warn(msg):
		sys.stderr.write("[WARNING] " + msg + "\n")


def get_supported_localizations(keypath):
	keyfile = open(keypath, 'r')
	key = keyfile.readline();
	#print("YouTube Data API v3 key: " + key)
	keyfile.close()

	conn = httplib.HTTPSConnection("www.googleapis.com")
	params = urllib.urlencode({'part' : 'snippet', 'key' : key})
	conn.request("GET", '/youtube/v3/i18nRegions?' + params)
	response = conn.getresponse()

	if (response.status != 200):
		print("Warning: Connection to YouTube data API failed")
		conn.close()
		return None

	data = json.load(response)
	conn.close()
	return data


def check(mccpath, i18n_data):
	f = open(mccpath, 'r')
	mcc_data = json.load(f);
	f.close();

	missing = i18n_data[:]
	for country in i18n_data:
		gl = country["snippet"]["gl"]
		for key in mcc_data:
			if mcc_data[key]["gl"] == gl:
				missing.remove(country)
				break;

	if len(missing) > 0:
		warn ("No MCC data for %d countries" % len(missing))
	else:
		print ("[INFO] All localization regions supported by YouTube have entries in " + mccpath)

	if verbose:
		for country in missing:
			snippet = country["snippet"]
			warn ("No MCC data for %s (%s)" % (snippet["name"], snippet["gl"]))

	return 0


def generate(mccpath, i18n_data):
	out_data = {}

	if mccpath and os.path.isfile(mccpath):
		f = open(mccpath, "r")
		out_data = json.load(f)
		f.close()
		temp = i18n_data[:]
		for country in i18n_data:
			gl = country["snippet"]["gl"]
			for key in out_data:
				if out_data[key]["gl"] == gl:
					temp.remove(country)
					break;
		i18n_data = temp

	for country in i18n_data:
		s = country["snippet"]
		try:
			response = raw_input ("Mobile country code(s) for %s (%s): " % (s["name"], s["gl"]) )
		except EOFError:
			sys.stdout.write('\n')
			continue
		except KeyboardInterrupt:
			sys.stdout.write('\n')
			break

		codes = re.split(r'\ +', response)
		for c in codes:
			mcc = int(c)
			if out_data.has_key(mcc):
				error("MCC code %d already exists for %s" % (mcc, out_data[mcc]["name"]))
				return 1
			out_data[mcc] = s;

	print ("[INFO] Writing MCC data to: " + mccpath)
	outfile = open(mccpath, 'w+')
	json.dump(out_data, outfile)
	outfile.close()

	return 0


def main(argv):
	global verbose
	keypath = None
	mccpath = None
	mode = None

	try:
		opts, args = getopt.getopt(argv,"hvm:k:c:",
			["help", "verbose", "mode=", "keyfile=", "mccfile="])
	except getopt.GetoptError:
		show_help()
		sys.exit(2)
	for opt, arg in opts:
		if opt == '-h':
			show_help()
			sys.exit(0)
		elif opt in ("-v", "--verbose"):
			verbose = True
		elif opt in ("-k", "--keyfile"):
			keypath = arg
		elif opt in ("-c", "--mccfile"):
			mccpath = arg
		elif opt in ("-m", "--mode"):
			mode = arg

	if not mode:
		show_help()
		sys.exit(1)

	if not keypath:
		show_help()
		sys.exit(1)

	if not (mode == "check" or mode == "generate"):
		error ("Invalid mode: " + mode)
		sys.exit(3)

	if (not os.path.isfile(keypath)):
		error ("Keyfile does not exist: " + keypath)
		sys.exit(3)

	if not mccpath:
		error ("MCC Data file not specified (--mccfile)")
		sys.exit(3)

	if mode == "check" and not os.path.isfile(mccpath):
		error ("MCC Data file not exist: %s" % mccpath)
		sys.exit(3)

	i18n_data = get_supported_localizations(keypath)
	if not i18n_data:
		sys.exit(1)

	i18n_data = i18n_data["items"]

	if (mode == "check"):
		return check (mccpath, i18n_data)
	else:
		return generate (mccpath, i18n_data)


if __name__ == "__main__":
	main(sys.argv[1:])
