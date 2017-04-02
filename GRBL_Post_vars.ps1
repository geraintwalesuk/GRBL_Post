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


##########################################################################################################
# define some variables
##########################################################################################################

# Line numbering
Set-Variable -Name lineNumberResequence -Value $false -Scope Global
Set-Variable -Name lineNumberStart -Value 100 -Scope Global
Set-Variable -Name lineNumberStep -Value 100 -Scope Global
Set-Variable -Name lineNumberFormat -Value "N{0:D4} " -Scope Global

# Include our own header
Set-Variable -Name includeHeader -Value $true -Scope Global

# Get current path
Set-Variable -Name currentPath -Value $PSScriptRoot -Scope Global

# some Defaults for prompts
Set-Variable -Name inputFileDefault -Value "input.gcode" -Scope Global
Set-Variable -Name outputPrefixDefault -Value "grbl_" -Scope Global

# Input filename
Set-Variable -Name inputFilename -Value $inputFileDefault -Scope Global

# output filename prefix
Set-Variable -Name outputPrefix -Value $outputPrefixDefault -Scope Global

# output filename
Set-Variable -Name outputFilename -Value ($outputPrefixDefault + $inputFileDefault) -Scope Global

# our log folder
Set-Variable -Name logFolder -Value "Log" -Scope Global

# our log file
Set-Variable -Name logname -Value ($(get-date -f yyyy-MM-dd-HH-mm-ss) + ".log") -Scope Global
Set-Variable -Name logfile -Value (Join-Path (Join-Path $currentPath $logFolder) $logname) -Scope Global

# pre process - will be prepended to the begining of the file
Set-Variable -Name preProcess -Value @("G0 Z10 F600","G0 X0 Y0 F600","M03") -Scope Global

# post process - will be appended to the end of the file
Set-Variable -Name postProcess -Value @("G0 Z10 F600","M05","G0 X0 Y0 F600") -Scope Global

# set to $true to stip all comments from the file
Set-Variable -Name stripComments -Value $false -Scope Global

##########################################################################################################
# START: MODAL CODES WE MAY NEED TO KEEP TRACK OF
##########################################################################################################

# Block parser pattern
# RegEx that extracts words and addresses from a block
Set-Variable -Name blockParsPattern -Value "((?:[A-Z]\s*[0-9]+\.{0,1}[0-9]*)+)" -Scope Global

# Comments pattern - detects comments
Set-Variable -Name commentsPattern -Value "^[Nn]*[\s]*[0-9]*[\s]*[%(]+.*$" -Scope Global

# Line number pattern - detects line numbers
Set-Variable -Name lineNumberPattern -Value "^.*N[0-9]+[\s]*" -Scope Global

# Temporary variable to store current non canned block words
Set-Variable -Name currentBlockWordsNonCanned -Value @() -Scope Global

# Canned Cycle Repeat words - If these are the only ones in a block and we are in a canned cycle
# then repeat the cycle 
Set-Variable -Name cannedRepeatGCodes -Value @("X","Y","Z","U","V","W") -Scope Global

# Valid words - all valid words - non coordinates,  To track triggering of a repeated canned cycle
Set-Variable -Name validWords -Value @("G","M") -Scope Global

# G81 G82 Related
Set-Variable -Name g81RelatedGCodes -Value @("X","Y","Z","U","V","W","R","L","F","P") -Scope Global

# G83 Related
Set-Variable -Name g83RelatedGCodes -Value @("X","Y","Z","U","V","W","R","L","F","P","Q") -Scope Global

# MODAL GROUP 1 CODES - These cancel a canned cycle
Set-Variable -Name modalGroup1GCodes -Value @("G0","G1","G2","G3","G38.2","G38.3","G38.4","G38.5","G80") -Scope Global

# motion mode gcodes
Set-Variable -Name motionModeGCodes -Value @("G0","G1","G2","G3") -Scope Global

# Coordinate System Select gcodes
Set-Variable -Name coordinateSystemSelectGCodes -Value @("G54","G55","G56","G57","G58","G59") -Scope Global

# Plane Select gcodes
Set-Variable -Name planeSelectGCodes -Value @("G17","G18","G19") -Scope Global

# Distance Mode gcodes
Set-Variable -Name distanceModeGCodes -Value @("G90","G91") -Scope Global

# Arc IJK Distance Mode gcodes
Set-Variable -Name arcIJKDistanceModeGCodes -Value @("G91.1") -Scope Global

# Feed Rate Mode gcodes
Set-Variable -Name feedRateModeGCodes -Value @("G93","G94") -Scope Global

# Units Mode gcodes
Set-Variable -Name unitsModeGCodes -Value @("G20","G21") -Scope Global

# Cutter Radius Compensation gcodes
Set-Variable -Name cutterRadiusCompensationGCodes -Value @("G40") -Scope Global

# Tool Length Offset gcodes
Set-Variable -Name toolLengthOffsetGCodes -Value @("G43.1","G49") -Scope Global

# Program Mode gcodes
Set-Variable -Name programModeGCodes -Value @("M0","M1","M2","M30") -Scope Global

# Spindle State gcodes
Set-Variable -Name spindleStateGCodes -Value @("M3","M4","M5") -Scope Global

# Coolant State gcodes
Set-Variable -Name coolantStateGCodes -Value @("M7","M8","M9") -Scope Global

# canned cycle gcodes
Set-Variable -Name cannedCycleGCodes -Value @("G73","G74","G76","G81","G82","G83","G84","G85","G86","G87","G88","G89","G80") -Scope Global

# retract gcodes
Set-Variable -Name retractGCodes -Value @("G98","G99") -Scope Global

##########################################################################################################
# END: MODAL CODES WE MAY NEED TO KEEP TRACK OF
##########################################################################################################


