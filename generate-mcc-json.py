#!/usr/bin/env python
import re
import json
import sys, getopt

def show_help():
    print('generate-mcc-json.py -i <inputfile> -o <outputfile>')


def main(argv):
    inputfile = None
    outputfile = None
    try:
        opts, args = getopt.getopt(argv,"hi:o:",["ifile=","ofile="])
    except getopt.GetoptError:
        show_help()
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            show_help()
            sys.exit()
        elif opt in ("-i", "--ifile"):
            inputfile = arg
        elif opt in ("-o", "--ofile"):
            outputfile = arg

    if not inputfile or not outputfile:
        show_help()
        sys.exit(1)

    f = open(inputfile, 'r')
    countries = {}
    for line in f:
            line = line.rstrip('\n')
            values = re.split(r'\t+', line)
            countries[values[0]] = values[1]
    f.close()

    out = open(outputfile, 'w')
    out.write(json.dumps(countries))
    out.close()

if __name__ == "__main__":
    main(sys.argv[1:])
