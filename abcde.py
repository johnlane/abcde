#!env python
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

version = "1.0-$Revision$"

help = """This is abcde version """ + version + """

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

def addstatus(status):
	pass

def log(status,logstring):
	pass	

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
		log("error","file",file,"cannot be read")
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

print checkstatus("test", "/tmp/status")
