#!/usr/bin/env python
# Copyright (c) 2007 Jesus Climent <jesus.climent@hispalinux.es>
# This code is hereby licensed for public consumption under either the
# GNU GPL v2 or greater, or Larry Wall's Artistic license - your choice.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
# $Id: abcde 232 2007-03-22 21:39:30Z data $

# import those needed modules.

import os
import re
import sys
import time
import getopt
import string
import select

__version__ = "1.0-$Revision$"

"""
abcde.py - A Better CD Encoder - python release
Copyright (C) 2007 Jesus Climent <jesus.climent@hispalinux.es>

"""

help = """This is abcde version """ + __version__ + """

usage: abcde.py [options] [tracks]
Options:
-1     Encode the whole CD in a single file
-a <action1[,action2]...>
       Actions to perform:
       cddb,read,normalize,encode,tag,move,replaygain,playlist,clean
-b     Enable batch normalization
-c <file>
       Specify a configuration file (overrides system and user config files)
-C <discid#>
       Specify discid to resume from (only needed if you no longer have the cd)
-d <device>
       Specify CDROM device to grab (flac uses a single-track flac file)
-D     Debugging mode (equivalent to sh -x abcde)
-e     Erase encoded track information from status file
-f     Force operations that otherwise are considered harmful. Read "man abcde"
-g     Use "lame --nogap" for MP3 encoding. Disables low disk and pipes flags
-h     This help information
#-i    Tag files while encoding, when possible (local only) -NWY-
-j <#> Number of encoder processes to run at once (localhost)
-k     Keep the wav tracks for later use
-l     Use low disk space algorithm
-L     Use local CDDB storage directory
-n     No lookup. Don't query CDDB, just create and use template
-N     Noninteractive. Never prompt for anything
-m     Modify playlist to include CRLF endings, to comply with some players
       WARNING: Deprecated. Use \"cue\" action
-o <type1[,type2]...>
       Output file type(s) (vorbis,mp3,flac,spx,mpc,wav,m4a). Defaults to vorbis
-p     Pad track numbers with 0's (if less than 10 tracks)
-P     Use UNIX pipes to read+encode without wav files
-q <level>
       Set quality level (high,medium,low)
-r <host1[,host2]...>
       Also encode on these remote hosts
-R     Use local CDDB in recursive mode
-s <field>
       Show dielfs from the CDDB info (year,genre)
-S <#> Set the CD speed
-t <#> Start the track numbering at a given number
-T <#> Same as -t but modifies tag numbering
-U     Do NOT use UNICODE (UTF8) tags and comments
-v     Show version number and exit
-V     Be a bit more verbose about what is happening behind the scenes
-x     Eject CD after all tracks are read
-w <comment>
       Add a comment to the CD tracks
-W <#> Contatenate CDs: -T #01 -w "CD #" 
-z     Use debug CDROMREADERSYNTAX option (needs cdparanoia)

Tracks is a space-delimited list of tracks to grab.
Ranges specified with hyphens are allowed (i.e., 1-5).

"""

def usage ():
	print help

def addstatus(status,file):
	try:
		file = open(file, "w")
	except:
		log("error","file",file,"cannot be read")
		return -1

def log(status,logstring):
	if re.compile("info").match(status):
		status = "[INFO]"
		pass
	elif re.compile("warning").match(status):
		status = "[WARNING]"
		pass
	elif re.compile("error").match(status):
		returncode = 1
		status = "[ERROR] %s\n"
		sys.stderr.write(status % logstring)
		sys.exit(1)
	else:
		return 1

def f_seq_row (min,max):
	try:
		seq = range(min,max)
		return seq
	except:
		log(error,"syntax error while processing track numbers")
		return -1

def f_seq_line (min,max):
	try:
		seq = range(min,max)
		return seq
	except:
		log(error,"syntax error while processing track numbers")
		return -1

#usage()

# get_first and get_last can be substituted by range[0] and range[:-1]

# checkstatus(string)
# Returns "0" if the string was found, returns 1 if it wasn't
# Puts the blurb content, if available, on stdout.
# Otherwise, returns "".
def checkstatus (string, file):
	
	patern = re.compile("^"+string+"(=.*)?$")

	try:
		file = open(file, "r")
	except:
		log("error","file "+file+" cannot be read")
		return -1

	blurb = []
	while 1:
		line = file.readline()
		if line == "": break
		blurb.append(re.search(patern,line).string)

	print blurb
	if blurb[-1]:
		return 0
	else:
		return 1

# which(program)
# checks where we can find a program in the path
def which(program):
	for path in string.split(os.environ["PATH"], ":"):
		if os.path.exists(os.path.join(path, program)):
			return os.path.join(path, program)



def main():
	try:
		opts, args = getopt.getopt(sys.argv[1:], "1a:bc:C:d:DefghjklLnNmopPqrRsStTUvVxwWz")
	except:
		log("error","unknown error")
		sys.stderr.write(usage % sys.argv[0])
		sys.exit(1)
	
	try:
		#abcde.setup()
		for opt, optarg in opts:
			print opt, optarg
			if opt == "-1": o_onetrack = "y"
			if opt == "-a": o_actions = optarg
			if opt == "-b": o_batchnormalize = "y"
			if opt == "-B": o_nobatchreplygain = "y"
			if opt == "-c": 
				o_configfile = str(optarg)
				try:
					if not re.compile("\.\/").search(o_configfile):
						o_configfile = os.environ.get("PWD", "./") + "/" + o_configfile
					os.path.exists(o_configfile)
				except:
					log("error",o_configfile+" cannot be read")
			if opt == "-C":
				if re.compile("abcde\.").match(optarg):
					o_discid = optarg
				else:
					o_discid = "abcde." + optarg
			if opt == "-d": o_cdrom = optarg
			if opt == "-D": o_debug = "y"
			if opt == "-h":
				usage()
				sys.exit(1)
			if opt == "-e": o_eraseencodedstatus = "y"
#			if opt == "-E": o_encoding
			if opt == "-f": o_force = "y"
			if opt == "-g": o_nogap = "y"
			if opt == "-j": o_maxprocs = optarg
			if opt == "-k": o_keepwavs = "y"
			if opt == "-l": o_lowdisk = "y"
			if opt == "-L": o_localcddb = "y"
			if opt == "-n": o_cddbavailable = "n"
			if opt == "-m": o_dosplaylist = "y"
			if opt == "-M": o_docue = "y"
			if opt == "-N": o_interactive = "n"
			if opt == "-o": o_outputtypes = optarg
			if opt == "-p": o_padtracks = "y"
			if opt == "-P": o_usepipes = "y"
			if opt == "-q": o_qualitylevel = optarg
			#if opt == "-r": o_remotehosts = optarg
			if opt == "-R": o_localcddbrecursive = "y"
			if opt == "-s": o_showcddbfields = "y"
			if opt == "-S": o_cdspeed = optarg
			if opt == "-t": o_starttracknumber = optarg
			if opt == "-T": 
				o_starttracknumber = optarg
				o_starttracknumbertag = "y"
			if opt == "-U": o_cddbproto = 5
			if opt == "-v":
				print "This is abcde v", __version__
				print "Usage: abcde.py [options] [tracks]"
				print "abcde -h for extra help"
				sys.exit(0)
			if opt == "-V": o_verbose = "y"
			if opt == "-x": o_eject = "y"
#			if opt == "-X": o_cue2discid = optarg
			if opt == "-w": o_comment = optarg
			if opt == "-W":
				if re.compile("^\d+$").search(optarg)
					o_starttracknumber = optarg + "01"
					o_starttracknumbertag = "y"
					o_comment = "CD" + optarg
				else:
					log("error","opt -W must be an integer")
					sys.exit(1)

	except: 
		#log("error","arguments were not correct")
		pass


#try:
##	checkstatus("test", "/tmp/status")
#	pass
#except:
#	sys.exit(1)

# -------------------------------
if __name__ == "__main__": main()

# b:is_python
# vim:tabstop=4:
