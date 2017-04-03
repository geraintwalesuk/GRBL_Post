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
# our functions
##########################################################################################################


Function Process-InputFile
{
	[cmdletbinding()]	
	Param (		
		$inputLines = ''
	)	

    foreach($line in $inputLines) {
    
        # strip out the line numbers
        $line = ($line -replace (Get-Var -Name lineNumberPattern), "")
        $newLines = $line

        # copy comments as they are
        if(!(Is-Comment -Value $line))
        {
            $newLines = Get-GRBL -line $line                }
        elseif($stripComments -eq $true)
        {
            $newLines = @()
        }

        # write out any lines we have
        foreach($newLine in $newLines)
        {
            if($newLine -replace " ", "" -ne "")
            {
                $lineNumber = ""                if(!(Is-Comment -Value $line))
                {                    $lineNumber = Get-NextLineNumber                }                        $("{0}{1}" -f $lineNumber,$newline) | Out-File -FilePath $outputFile -Append -Encoding default            }
        }
    }
}

Function Get-InputFileName
{
    $inputFilename = (Read-HostDefault "Input Filename? [$inputFileDefault]" $inputFileDefault)
    $inputFile = Join-Path $currentPath $inputFilename
    if(!(Test-Path -Path $inputFile))
    {
        trace -message "Can't fine $inputFile" -outfile1 $logfile -ForegroundColor Red
        exit
    }
    return $inputFile
}

Function Get-OutputFilename
{
    $outputPrefix = (Read-HostDefault "Output prefix? [$outputPrefixDefault]" $outputPrefixDefault)

    $outputFilename = $outputPrefix + $inputFilename
    $outputFile = Join-Path -Path $currentPath -ChildPath $outputFilename
    if(Test-Path -Path $outputFile)
    {
        Remove-Item -Path $outputFile -Force -ErrorAction SilentlyContinue
    }
    return $outputFile
}

Function Write-Header
{
	$inputFile = Get-Var -Name inputFile
	$outputFile = Get-Var -Name outputFile
    if((Get-Var -Name includeHeader))
    {
        Write-Comment -comment $("GRBL PostProcess script for FreeCAD") | Out-File -FilePath $outputFile -Append -Encoding default
        Write-Comment -comment $("Script File   : " + $(Join-Path -Path $PSScriptRoot -ChildPath $MyInvocation.MyCommand.Name)) | Out-File -FilePath $outputFile -Append -Encoding default
        Write-Comment -comment $("Input File    : " + $inputFile) | Out-File -FilePath $outputFile -Append -Encoding default
        Write-Comment -comment $("Output File   : " + $outputFile) | Out-File -FilePath $outputFile -Append -Encoding default
        Write-Comment -comment $("Date          : " + $(Get-Date)) | Out-File -FilePath $outputFile -Append -Encoding default
    }
}

Function Write-PreProcess
{
    Write-Comment -comment "Pre-Process Start" | Out-File -FilePath $outputFile -Append -Encoding default
    foreach($line in $preProcess) {
        $lineNumber = Get-NextLineNumber        $("{0}{1}" -f $lineNumber,$line) | Out-File -FilePath $outputFile -Append -Encoding default    }
    Write-Comment -comment "Pre-Process End" | Out-File -FilePath $outputFile -Append -Encoding default
}

Function Write-PostProcess
{
    Write-Comment -comment "Post-Process Start" | Out-File -FilePath $outputFile -Append -Encoding default
    foreach($line in $postProcess) {
        $lineNumber = Get-NextLineNumber        $("{0}{1}" -f $lineNumber,$line) | Out-File -FilePath $outputFile -Append -Encoding default    }
    Write-Comment -comment "Post-Process End" | Out-File -FilePath $outputFile -Append -Encoding default
}

Function Write-OurPreProcess
{
    $return = @()
    $return += (Write-Comment -comment  ("found G" + (Get-ThisG)))
    $return += (Write-Comment -comment  "Starting our own implementation...")
    $return += Write-CommentAllVars
    $nonCannedWords = (Get-Var -Name currentBlockWordsNonCanned)
    if($nonCannedWords)
    {
        $return += (Write-Comment -comment  (("Including non Canned Words: " + (Get-Var -Name currentBlockWordsNonCanned) -join " ")))
        $return += (((Get-Var -Name currentBlockWordsNonCanned) -join " "))
    }
    return $return
}

Function Write-OurPostProcess
{
    $return = @()
    $return += (Write-Comment -comment  ("ending our implementation of G" + (Get-ThisG)))
    return $return
}

Function Write-Comment()
{
	[cmdletbinding()]	
	Param (		
		[parameter(ValueFromPipeline=$True)]		
		[string]$comment = ''
	)	
    if($stripComments -eq $True)
    {
        return $null
    }

    return $("(" + $comment + ")")

}

Function Is-Comment
{
	[cmdletbinding()]	
	Param (		
		[string]$Value = ''
	)	

    return ([regex]::IsMatch($value,(Get-Var -Name commentsPattern)))

}

Function Write-CommentAllVars
{
    $return = @()
    $globalVars = Get-Variable | Where-Object { $_.Name -like "GLOBAL*" } -ErrorAction SilentlyContinue
    $localVars = Get-Variable | Where-Object { $_.Name -like "LOCAL*" } -ErrorAction SilentlyContinue

    $globalVars | foreach { $return += (Write-Comment -comment (("{0} : {1} = {2}" -f $MyInvocation.MyCommand,$_.Name,$_.Value))) }
    $localVars | foreach { $return += (Write-Comment -comment (("{0} : {1} = {2}" -f $MyInvocation.MyCommand,$_.Name,$_.Value))) }

    return $return
}




# machine functions

Function GRBL-MoveXY
{
	[cmdletbinding()]	
	Param (		
		[string]$X = '',
		[string]$Y = '',
        [switch]$Rapid
	)

    $return = @()
    $_G = ""
    $_X = ""
    $_Y = ""

    if($Rapid){ $_G = "G0 " }
    else{ $_G = "G1" }

    if($X){$_X = "X$X "}
    else{$_X = ""}

    if($Y){$_Y = "Y$Y "}
    else{$_Y = ""}

    $return += (Write-Comment -comment  ("{0} : MOVE {1} {2}" -f $MyInvocation.MyCommand,$_X,$_Y))
    $return += "$_G$_X$_Y"
	return $return
}

Function GRBL-MoveZ
{
	[cmdletbinding()]	
	Param (		
		[string]$Z = '',
		[string]$F = '',
        [switch]$Rapid
	)

    $return = @()
    $_G = ""
    $_Z = ""
    $_F = ""


    if($Rapid){ $_G = "G0 " }
    else
    { 
        $_G = "G1 " 
        $_F = "F$F "
    }

    if($Z){$_Z = "Z$Z "}
    else{$_Z = ""}

    $return += (Write-Comment -comment  ("{0} : MOVE {1} {2}" -f $MyInvocation.MyCommand,$_Z,$_F))
    $return += "$_G$_Z$_F"
	return $return

}

Function GRBL-Preliminary
{
	[cmdletbinding()]	
	Param (		
		[string]$X = '',
		[string]$Y = '',
		[string]$R = ''
	)
    
    $return = @()
    # rapid move to R
    $return += (Write-Comment -comment  ("{0} : RAPID MOVE TO R{1}" -f $MyInvocation.MyCommand, $R))
    $return += GRBL-MoveZ -Z $R -Rapid
    # move to x and y
    $return += (Write-Comment -comment  ("{0} : RAPID MOVE TO 'X,Y' {1},{2}" -f $MyInvocation.MyCommand,$X,$Y))
    $return += GRBL-MoveXY -X $X -Y $Y -Rapid
    return $return
}

Function GRBL-Drill
{
	[cmdletbinding()]	
	Param (		
		[string]$Z = '',
		[string]$F = ''
	)
    $return = @()
    $return += (Write-Comment -comment  ("{0} : DRILL TO Z{1}$Z at FEEDRATE F{2}" -f $MyInvocation.MyCommand,$Z,$F))
    $return += GRBL-MoveZ -Z $Z -F $F
	return $return
}

Function GRBL-Retract
{
	[cmdletbinding()]	
	Param (		
		[float]$Z = ''	)

    $return = @()
    $return += (Write-Comment -comment  ("{0} : Rapid RETRACT TO Z$Z" -f $MyInvocation.MyCommand))
    $return += GRBL-MoveZ -Z $Z -Rapid
	return $return
}

Function GRBL-Dwell
{
	[cmdletbinding()]	
	Param (		
		[string]$P = ''
	)

    $return = @()
    $return += (Write-Comment -comment  ("{0} : DWELL $P Seconds" -f $MyInvocation.MyCommand))
    $return += "G4 $P"
	return $return

}


# Variable helper functions

Function Get-ThisVars
{
	[cmdletbinding()]	
	Param (		
		#[string[]]$Filter = '',
		[string[]]$Exclude = ''
	)
    $ret = @()
	$tmp = @()
    $excludeFilter = @()

    $variableName = "GLOBAL_THIS_*"
    $Exclude | foreach {$excludeFilter += $($variableName + $_)} 
    $vars = Get-Variable -Name ($variableName) | foreach {$tmp += $_}
    $tmp = $tmp | Where-Object { $_.Name.Substring(0,1) -notin $excludeFilter }
    return $tmp
}

Function This-HasCoordinates
{
    $repeatGCodes = Get-Var -Name cannedRepeatGCodes
    foreach($word in $repeatGCodes)
    {
        if(Get-ThisGCode -Word $word)
        {
            return $true
        }
    }
    return $false
}

Function Get-ThisG
{
    return (Get-ThisGCode -Word "G")
}

Function Get-ThisR
{
    return (Get-ThisGCode -Word "R")
}

Function Get-ThisZ
{
    return (Get-ThisGCode -Word "Z")
}

Function Get-ThisY
{
    return (Get-ThisGCode -Word "Y")
}

Function Get-ThisX
{
    return (Get-ThisGCode -Word "X")
}

Function Get-ThisF
{
    return (Get-ThisGCode -Word "F")
}

Function Get-ThisP
{
    return (Get-ThisGCode -Word "P")
}

Function Get-ThisQ
{
    return (Get-ThisGCode -Word "Q")
}

Function Get-ThisGCode
{
	[cmdletbinding()]	
	Param (		
		[string]$Word = ''
	)	
    return (Get-ThisVar -Name ("GCODE_$Word"))
}

Function Get-ThisVar
{
	[cmdletbinding()]	
	Param (		
		[string]$Name = ''
	)	
    $variableName = "GLOBAL_THIS_" + $Name
    $ret = Get-Var -Name $variableName
    return $ret
}

Function Get-LastRETRACT
{
    $lastVariableName = "RETRACT"
    return (Get-LastVar -Name $lastVariableName)
}

Function Get-LastG
{
    return (Get-LastGCode -Word "G")
}

Function Get-LastR
{
    return (Get-LastGCode -Word "R")
}

Function Get-LastZ
{
    return (Get-LastGCode -Word "Z")
}

Function Get-LastY
{
    return (Get-LastGCode -Word "Y")
}

Function Get-LastX
{
    return (Get-LastGCode -Word "X")
}

Function Get-LastF
{
    return (Get-LastGCode -Word "F")
}

Function Get-LastP
{
    return (Get-LastGCode -Word "P")
}

Function Get-LastQ
{
    return (Get-LastGCode -Word "Q")
}

Function Get-LastGCode
{
	[cmdletbinding()]	
	Param (		
		[string]$Word = ''
	)	
    return (Get-LastVar -Name ("GCODE_$Word"))
}

Function Get-LastVar
{
	[cmdletbinding()]	
	Param (		
		[string]$Name = ''
	)	
    $variableName = "GLOBAL_LAST_" + $Name
    $ret = Get-Var -Name $variableName
    return $ret
}

Function Get-Var
{
	[cmdletbinding()]	
	Param (		
		[string]$Name = ''
	)	
    
    return ((Get-Variable -Name $Name -Scope Global -ErrorAction SilentlyContinue).Value)
}


Function Set-ThisVar
{
	[cmdletbinding()]	
	Param (		
		[string]$Name = '',
        [string]$Value
	)	
    $variableName = "GLOBAL_THIS_" + $Name
    Set-Var -Name $variableName -value $Value
}

Function Set-LastVar
{
	[cmdletbinding()]	
	Param (		
		[string]$Name = '',
        [string]$Value
	)	
    $variableName = "GLOBAL_LAST_" + $Name
    $variableName | Set-Var -value $Value
}

Function Set-Var
{
	[cmdletbinding()]	
	Param (		
		[string]$Name = '',
        [string]$Value

	)	
    Set-Variable -Name $Name -Value $Value -Scope Global
}

Function Clear-ThisVars
{
	[cmdletbinding()]	
	Param (		
		[switch]$Remove = $false
	)	
    
    [System.Management.Automation.PSVariable[]]$vars = (Get-Variable | Where-Object { $_.Name -like "GLOBAL_THIS*" }) 
    $vars | Clear-Vars -Remove:$Remove
}

Function Clear-LastVars
{
	[cmdletbinding()]	
	Param (		
		[switch]$Remove
	)	
    
    [System.Management.Automation.PSVariable[]]$vars = (Get-Variable | Where-Object { $_.Name -like "GLOBAL_LAST*" }) 
    $vars | Clear-Vars -Remove:$Remove
}

Function Clear-Vars
{
	[cmdletbinding()]	
	Param (		
		[parameter(ValueFromPipeline=$True)]		
		[System.Management.Automation.PSVariable[]]$Vars,
		[switch]$Remove

	)	
    Begin 
    {
    }
	
    Process  
    {	
        foreach($v in $Vars)
        {
            $v | Clear-Variable
            if($Remove)
            {
                $v | Remove-Variable
            }
        }
    }
    
    End{}
}


Function Copy-LastToThis
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [String]$Name
    )
    Set-ThisVar -Name $Name -Value (Get-LastVar -Name $Name)
}

Function Copy-ThisToLast
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [String]$Name
    )
    Set-LastVar -Name $Name -Value (Get-ThisVar -Name $Name)
}







# Misc functions

Function Create-Folders {

    New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
	
}


Function Trace ($message, $outfile1, $outfile2, [ConsoleColor]$ForegroundColor = [ConsoleColor]::White) {

	$timestamp = Get-Date -Format "yyyy-MM-dd-HH:mm:ss"

    # write multi line log
    # split the message into separate lines (if any)

    $lines = $message -split '[\r\n]'
    foreach($line in $lines)
    {
        $out = ("{0,-22}:{1}{2}" -f $timestamp, " ", ($line.Trim()))

        Write-Host ($out) -ForegroundColor:$ForegroundColor
	    if (($outfile1)) { ($out) | out-file $outfile1 -encoding ASCII -append }
	    if (($outfile2)) { ($out) | out-file $outfile2 -encoding ASCII -append }
    }

}


function Read-HostDefault
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [String]$Prompt,

        [Parameter(Mandatory=$true)]
        [String]$Default
    )

    $response = Read-Host $Prompt
    if ($response -eq "")
    {
        return $Default
    }
    else
    {
        return $response
    }
}


function Read-HostMandatory
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [String]$Prompt
    )

    $valueGiven = ""
    while ($valueGiven -eq "")
    {
        $valueGiven = Read-Host $Prompt
    }        

    return $valueGiven
}


function Delete-File
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [String]$Filepath
    )

    Trace ("Deleting file {0}..." -f $Filepath) $logfile -ForegroundColor Green
    try
    {
        # there really should be some sanity checking here!
        [System.IO.File]::Delete($Filepath)
        Trace ("OK") $logfile -ForegroundColor Green
    }
    catch
    {
        Trace ("Failed!") $logfile -ForegroundColor Red
    }
}



function Parse-Date([string]$date)
{
    $result = 0
    if (!([DateTime]::TryParse($date, [ref]$result)))
    {
        return $null
     }

    $result
}


function Convert-DateString ([String]$Date, [String[]]$Format)
{
   $result = New-Object DateTime
 
   $convertible = [DateTime]::TryParseExact(
      $Date,
      $Format,
      [System.Globalization.CultureInfo]::InvariantCulture,
      [System.Globalization.DateTimeStyles]::None,
      [ref]$result)
 
   if ($convertible) { return $result }
   return $null
}


Function Get-NextLineNumber
{
    $return = $null
    if((Get-Var -Name lineNumberResequence) -eq $true)
    {
        $lineNumberFormat = (Get-Var -Name lineNumberFormat)
        $return = "$lineNumberFormat" -f (Get-Var -Name lineNumberStart)
        Set-Variable -Name lineNumberStart -Value ((Get-Var -Name lineNumberStart) + (Get-Var -Name lineNumberStep)) -Scope Global
    }

    return $return

}


##########################################################################################################

