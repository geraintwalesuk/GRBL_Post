# GRBL_Post

##########################################################################################################
# GRBL_Post: GRBL post processor to implement Canned Cycles
#   Copyright (C) 2017  Geraint Evans
##########################################################################################################
# This file is part of GRBL_Post.
#
#    GRBL_Post is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    GRBL_Post is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with GRBL_Post.  If not, see <http://www.gnu.org/licenses/>.
##########################################################################################################
#
# GRBL Post Process script for FreeCad (or any other GCode file)
#
# If exporting from FreeCAD then either use no post process or the linuxcnc post process
# Copy the gcode file to the same location as this script, supply the input filename and
# the output prefix for the output filename.
#
# Currently only handles absolute position G81,G82 and G83 Canned Cycles. 
# Relative position not tested
#
# This is my interpretation of the canned cycles.
# 
#
##########################################################################################################


# List of possible Canned Cycles

# G Code	Purpose											Peck	Retract			Bottom of Hole
##########################################################################################################
# G73	    High-speed Peck Drilling for Shallow Holes		Yes		Rapid	
# G74	    Left-hand Tapping Cycle									Feed			Dwell -> Spindle CW
# G76	    Fine Boring Cycle										Rapid			Oriented Stop
# G81	    Drilling Cycle without Peck,							Rapid 			
# 			Hole Depths <= 3 Diameters			
# G82	    Spot Drilling Cycle										Rapid			Dwell
# G83	    Peck Drilling for Deeper Holes					Yes		Rapid	
# G84	    Tapping Cycle											Feed			Dwell -> Spindle CCW
# G85	    Boring Cycle											Feed	
# G86	    Boring Cycle											Rapid			Spindle Stop
# G87	    Back Boring Cycle										Rapid			Spindle CW
# G88	    Boring Cycle									Mnual					Dwell -> Spindle Stop
# G89	    Boring Cycle											Feed			Dwell
##########################################################################################################


##########################################################################################################
#
# TODO:
#
# Use a custom object instead of global variables
#
##########################################################################################################
