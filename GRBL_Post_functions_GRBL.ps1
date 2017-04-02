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


Function Get-GRBL-G81
{
    #G81 (X- Y- Z-) or (U- V- W-) R- L-
    #G82 (X- Y- Z-) or (U- V- W-) R- L- P-
    
    $return = @()

    # Add comments - just for debugging at the moment
    $return += (Write-OurPreProcess)

    # grab the last set of words
    [float]$lastZ = Get-LastZ
    $lastRetract = Get-LastRETRACT
                    
    # grab the current set of words
    [float]$thisX = Get-ThisX
    [float]$thisY = Get-ThisY
    [float]$thisZ = Get-ThisZ
    [float]$thisF = Get-ThisF
    if(!($thisF))
    {
        $thisF = Get-LastF
    }
    [float]$thisP = Get-ThisP
    [float]$thisR = Get-ThisR

    # Preliminary move
    $return += (GRBL-Preliminary -X $thisX -Y $thisY -R $thisR)

    # now drill - not sure if we should add the Z and R here.  Read two different descriptions
    #$return += GRBL-Drill -Z ([float]$thisZ + [float]$thisR) -F $thisF
    $return += GRBL-Drill -Z ([float]$thisZ) -F $thisF

    # do we need to dwell?
    if($thisP)
    {
        #TO DO: Add dwell
    }

    # rapid return to R or previous Z
    $return += (Write-Comment -comment  ("LAST RETRACT " + $lastRetract))
    if($lastRetract -eq "G99")
    {
        $return += (GRBL-Retract -Z $thisR)
    }
    else
    {
        $return += (GRBL-Retract -Z (@($lastZ,$thisR) | Measure -Maximum).Maximum)
    }

    $return += (Write-OurPostProcess)
    return $return

}


Function Get-GRBL-G83
{
    #G83 (X- Y- Z-) or (U- V- W-) R- L- Q-
    
    $return = @()

    # Add comments - just for debugging at the moment
    $return += (Write-OurPreProcess)

    # grab the last set of words
    [float]$lastZ = Get-LastZ
    $lastRetract = Get-LastRETRACT
                    
    # grab the current set of words
    [float]$thisX = Get-ThisX
    [float]$thisY = Get-ThisY
    [float]$thisZ = Get-ThisZ
    [float]$thisF = Get-ThisF
    if(!($thisF))
    {
        $thisF = Get-LastF
    }
    [float]$thisP = Get-ThisP
    [float]$thisR = Get-ThisR

    # Preliminary move
    $return += (GRBL-Preliminary -X $thisX -Y $thisY -R $thisR)

    # start the peck
    
    [float]$step = [float](Get-ThisQ)

    [float]$currentZ = ([float]$thisR - $step)
    
    while($currentZ -ge [float]$thisZ)
    {
        # now drill
        $return += GRBL-Drill -Z $currentZ -F $thisF
        # rapid return to R
        $return += (GRBL-Retract -Z $thisR)
        # rapid return to Previous depth less 0.01mm
        $return += (GRBL-Retract -Z ($currentZ + 0.01))
        $currentZ -= $step
        if($currentZ -lt [float]$thisZ)
        {
            $currentZ = $thisZ
            $return += GRBL-Drill -Z $currentZ -F $thisF
            # rapid return to R
            $return += (GRBL-Retract -Z $thisR)
            $currentZ -= $step
        }
    }

    # rapid return to R or previous Z
    $return += (Write-Comment -comment  ("LAST RETRACT " + $lastRetract))
    if($lastRetract -eq "G99")
    {
        $return += (GRBL-Retract -Z $thisR)
    }
    else
    {
        $return += (GRBL-Retract -Z (@($lastZ,$thisR) | Measure -Maximum).Maximum)
    }

    $return += (Write-OurPostProcess)
    return $return

}


Function Get-GRBL 
{	

	[cmdletbinding()]	
	Param (		
		[string]$line = ''
	)	

    $return = @()

    # clear the THIS variables - we're only interested in the current words passed in here
    Clear-ThisVars -Remove

       
	Try  {				

        # grab all the values and save in global scope so we can retrieve them at a later time
        GRBL-ParseBlock -block $line -saveToVar "THIS"

        # if this is just coordinates then assume we are in the middle of
        # a canned cycle.  So copy the relevant fields back to "THIS" and run the last cycle
        # with the new coordinates
        # Not 100% sure but for now assume if there are no G codes but there are coordinates
        # then assume re-cycle
        if(!(Get-ThisG) -and (This-HasCoordinates))
        {
            # copy the last canned cycle words to this
            Copy-LastToThis -Name "CANNEDCYCLE"
            Copy-LastToThis -Name "F"
            Copy-LastToThis -Name "R"
            Copy-LastToThis -Name "P"
            Copy-LastToThis -Name "Q"

        }




        # check for G81 - Drilling Cycle without Peck
        if(("G81","G82") -contains $GLOBAL_THIS_CANNEDCYCLE)
        {
            $return += Write-Comment -comment $line
            $return += Get-GRBL-G81
        }

        elseif(("G83") -contains $GLOBAL_THIS_CANNEDCYCLE)
        {
            $return += Write-Comment -comment $line
            $return += Get-GRBL-G83
        }

        # nothing to do so pass back the line as is
        else
        {
            $return += $line
        }

        # grab all the values and save in global scope so we can retrieve them at a later time
        GRBL-ParseBlock -block $line -saveToVar "LAST"


    }
    catch{$return = $line}
    finally
    {
        $return
    }
}


Function GRBL-ParseBlock
{
	[cmdletbinding()]	
	Param (		
		[parameter(ValueFromPipeline=$True)]		
		[string]$block = '',
        [string]$saveToVar = "LAST"
	)	
    

    # grab all the words and addresses and split into an array
    $regEx = Get-Var -Name blockParsPattern
    $commands = [regex]::Split($block,$regEx) | foreach {$_ -replace ' ', ''} |  Where-Object {$_ -ne ""}
    
    # grab all non canned cycle related words and strip line numbers
    $nonCanned = $commands | 
        Where-Object {($($_).ToString().Substring(0,1) -notin $g81RelatedGCodes) -and ($($_).ToString().Substring(0,1) -notin $g83RelatedGCodes)} | 
        Where-Object {$_ -notin (Get-Var -Name cannedCycleGCodes)} | 
        Where-Object {!([regex]::IsMatch($_,(Get-Var -Name lineNumberPattern)))}
    Set-Variable -Name currentBlockWordsNonCanned -Value $nonCanned -Scope Global

    #process the words in the order we received them.  If there are any conflicting words then we end up just using the last one found
    foreach($command in $commands)
    {
        # save the word and address for reference
        $variableName = ("GLOBAL_" + $saveToVar + "_GCODE_") + $command.Substring(0,1)
        $variableValue = $command.Substring(1)
        Set-Var -Name $variableName -Value $variableValue 

        # check for motionModeGCodes
        if($motionModeGCodes -contains $command){Set-Var -Name ("GLOBAL_" + $saveToVar + "_MOTION_MODE") -Value $command }
        
        # check for retract
        if($retractGCodes -contains $command){Set-Var -Name ("GLOBAL_" + $saveToVar + "_RETRACT") -Value $command }
        
        # check for canned cycles
        if($cannedCycleGCodes -contains $command){Set-Var -Name ("GLOBAL_" + $saveToVar + "_CANNEDCYCLE") -Value $command }
    
        # check for coordinateSystemSelectGCodes
        if($coordinateSystemSelectGCodes -contains $command){Set-Var -Name ("GLOBAL_" + $saveToVar + "_COORDINATE_SYSTEM") -Value $command }
        
        # check for distanceModeGCodes
        if($distanceModeGCodes -contains $command){Set-Var -Name ("GLOBAL_" + $saveToVar + "_DISTANCE_MODE") -Value $command }

        # check for modalGroup1GCodes - Cancel Canned Cycles if we receive another move word
        if($modalGroup1GCodes -contains $command){Set-Var -Name ("GLOBAL_" + $saveToVar + "_CANNEDCYCLE") -Value "G80" }


    }

}

