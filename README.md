# GRBL_Post

################################################################################################
# GRBL_Post: GRBL post processor to implement Canned Cycles
#   Copyright (C) 2017  Geraint Evans
################################################################################################
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
################################################################################################


################################################################################################
#
# TODO:
#
# Use a custom object instead of global variables
#
################################################################################################
