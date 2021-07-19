#############################################################################
#
# (C) 2021 Cadence Design Systems, Inc. All rights reserved worldwide.
#
# This sample script is not supported by Cadence Design Systems, Inc.
# It is provided freely for demonstration purposes only.
# SEE THE WARRANTY DISCLAIMER AT THE BOTTOM OF THIS FILE.
#
#############################################################################

package require PWI_Glyph 2

pw::Script loadTk

set Params(radius) 10
set Params(length) 40

# Make the cylindrical revolved surface
proc makeCylinderDB { r l } {
  set seg [pw::SegmentSpline create]
  $seg addPoint "[expr -0.5 * $l] $r 0"
  $seg addPoint "[expr 0.5 * $l] $r 0"
  set line [pw::Curve create]
  $line addSegment $seg

  set pipe [pw::Surface create]
  $pipe revolve -angle 360 $line {0 0 0} {1 0 0}
  pw::Display update

  return $pipe
}

# Make connectors and domain on database
proc makeDomain { db avgspace } {
  set omethod [pw::Connector getCalculateDimensionMethod]
  set ospacing [pw::Connector getCalculateDimensionSpacing]
  pw::Connector setCalculateDimensionMethod Spacing
  pw::Connector setCalculateDimensionSpacing $avgspace

  set cons [pw::Connector createOnDatabase $db]
  foreach con $cons {
    $con calculateDimension
  }

  set dom [pw::DomainStructured createOnDatabase [list $db]]

  pw::Display update
  pw::Connector setCalculateDimensionMethod $omethod
  pw::Connector setCalculateDimensionSpacing $ospacing

  return $dom
}

# Extrude domain inward
proc extrudeDomain { dom } {
  global Params
 
  set face [pw::FaceStructured create]
  $face addDomain $dom
  set block [pw::BlockStructured create]
  $block addFace $face
  $block setExtrusionBoundaryCondition [list 1 1] ConstantX
  $block setExtrusionBoundaryCondition [list 3 1] ConstantX
  $block setExtrusionSolverAttribute DirectionFlipped 1
  $block setExtrusionSolverAttribute NormalInitialStepSize \
    [expr $Params(radius)/100.0]
  $block setExtrusionSolverAttribute StopAtHeight [expr $Params(radius)/3.0]

  set mode [pw::Application begin ExtrusionSolver $block]

  set result Completed
  while {1 == [string equal $result Completed]} {
    $mode run
    set result [lindex [$mode getRunResult] 0]
    switch $result {
      Error -
      SolverFailure {
        puts "Extrusion solver encountered an error"
      }
      Completed -
      StopCriteria {
      }
    }
  }

  $mode end
}

# Build a pipe mesh on a cylinder database
proc buildMesh { } {
  global Params

  wm withdraw .

  set pipeDB [makeCylinderDB $Params(radius) $Params(length)]
  pw::Display resetView
  set view [pw::Display getCurrentView]
  pw::Display setCurrentView [lreplace $view 2 3 {0.6 0.6 0.0} 60.0]
  set spacing [expr ($Params(radius) + $Params(length)) / 50.0]
  set Domain [makeDomain $pipeDB $spacing]
  extrudeDomain $Domain

  destroy .
}

# Check text field input
proc checkInput { w param text action } {
  global Params
  # Ignore force validations
  if {$action == -1} {
    return 1
  }

  if {![string is double $text]} {
    $w configure -bg "#FFCCCC"
  } else {
    $w configure -bg "#FFFFFF"
  }

  if {[string is double $Params(radius)] && \
        [string is double $Params(length)] && \
        $Params(radius) > 0.0 && $Params(length) > 0.0} {
    .buttons.ok configure -state normal
  } else {
    .buttons.ok configure -state disabled
  }
  return 1
}

# Create a text input field
proc makeInputField { parent name title param {width 7} {valid ""}} {
  global Params
  set row [lindex [grid size $parent] 1]
  label .lbl$name -text $title
  entry .ent$name -textvariable Params($param) -width $width -justify right
  if { [string compare $valid ""] != 0 } {
    .ent$name configure -validate all
    .ent$name configure -validatecommand $valid
  }

  grid .lbl$name -row $row -column 0 -sticky e -in $parent
  grid .ent$name -row $row -column 1 -sticky w -in $parent
  grid columnconfigure $parent "0 1" -weight 1

  return $parent.$name
}

# Build the Tk interface
proc makeWindow { } {
  global Params
  wm title . "Extruded Pipe"
  label .title -text "Create Extruded Pipe"
  set font [.title cget -font]
  set wfont [font create -family [font actual $font -family] -weight bold]
  .title configure -font $wfont
  pack .title -side top

  pack [frame .hr1 -relief sunken -height 2 -bd 1] \
        -side top -padx 2 -fill x -pady 1
  pack [frame .inputs] -fill x -padx 2 -expand 1

  makeInputField .inputs radius "Radius:" radius 7 [list \
        checkInput %W radius %P %d]
  makeInputField .inputs length "Length:" length 7 [list \
        checkInput %W length %P %d]

  pack [frame .hr2 -relief sunken -height 2 -bd 1] \
        -side top -padx 2 -fill x -pady 1

  pack [frame .buttons] -fill x -padx 2 -pady 1 -side bottom
  pack [button .buttons.cancel -text "Cancel" -command { exit }] \
        -side right -padx 2
  pack [button .buttons.ok -text "OK" -command {buildMesh}] \
        -side right -padx 2

  pack [label .buttons.logo -image [cadenceLogo] -bd 0 -relief flat] \
      -side left -padx 5

  bind . <KeyPress-Escape> { .buttons.cancel invoke }
  bind . <Control-KeyPress-Return> { .buttons.ok invoke }
}

proc cadenceLogo {} {
  set logoData "
R0lGODlhgAAYAPQfAI6MjDEtLlFOT8jHx7e2tv39/RYSE/Pz8+Tj46qoqHl3d+vq62ZjY/n4+NT
T0+gXJ/BhbN3d3fzk5vrJzR4aG3Fubz88PVxZWp2cnIOBgiIeH769vtjX2MLBwSMfIP///yH5BA
EAAB8AIf8LeG1wIGRhdGF4bXD/P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENlaGlIe
nJlU3pOVGN6a2M5ZCI/PiA8eDp4bXBtdGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1w
dGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYxIDY0LjE0MDk0OSwgMjAxMC8xMi8wNy0xMDo1Nzo
wMSAgICAgICAgIj48cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudy5vcmcvMTk5OS8wMi
8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmY6YWJvdXQ9IiIg/3htbG5zO
nhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIiB4bWxuczpzdFJlZj0iaHR0
cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL3NUcGUvUmVzb3VyY2VSZWYjIiB4bWxuczp4bXA9Imh
0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0idX
VpZDoxMEJEMkEwOThFODExMUREQTBBQzhBN0JCMEIxNUM4NyB4bXBNTTpEb2N1bWVudElEPSJ4b
XAuZGlkOkIxQjg3MzdFOEI4MTFFQjhEMv81ODVDQTZCRURDQzZBIiB4bXBNTTpJbnN0YW5jZUlE
PSJ4bXAuaWQ6QjFCODczNkZFOEI4MTFFQjhEMjU4NUNBNkJFRENDNkEiIHhtcDpDcmVhdG9yVG9
vbD0iQWRvYmUgSWxsdXN0cmF0b3IgQ0MgMjMuMSAoTWFjaW50b3NoKSI+IDx4bXBNTTpEZXJpZW
RGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6MGE1NjBhMzgtOTJiMi00MjdmLWE4ZmQtM
jQ0NjMzNmNjMWI0IiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOjBhNTYwYTM4LTkyYjItNDL/
N2YtYThkLTI0NDYzMzZjYzFiNCIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g
6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PgH//v38+/r5+Pf29fTz8vHw7+7t7Ovp6Ofm5e
Tj4uHg397d3Nva2djX1tXU09LR0M/OzczLysnIx8bFxMPCwcC/vr28u7q5uLe2tbSzsrGwr66tr
KuqqainpqWko6KhoJ+enZybmpmYl5aVlJOSkZCPjo2Mi4qJiIeGhYSDgoGAf359fHt6eXh3dnV0
c3JxcG9ubWxramloZ2ZlZGNiYWBfXl1cW1pZWFdWVlVUU1JRUE9OTUxLSklIR0ZFRENCQUA/Pj0
8Ozo5ODc2NTQzMjEwLy4tLCsqKSgnJiUkIyIhIB8eHRwbGhkYFxYVFBMSERAPDg0MCwoJCAcGBQ
QDAgEAACwAAAAAgAAYAAAF/uAnjmQpTk+qqpLpvnAsz3RdFgOQHPa5/q1a4UAs9I7IZCmCISQwx
wlkSqUGaRsDxbBQer+zhKPSIYCVWQ33zG4PMINc+5j1rOf4ZCHRwSDyNXV3gIQ0BYcmBQ0NRjBD
CwuMhgcIPB0Gdl0xigcNMoegoT2KkpsNB40yDQkWGhoUES57Fga1FAyajhm1Bk2Ygy4RF1seCjw
vAwYBy8wBxjOzHq8OMA4CWwEAqS4LAVoUWwMul7wUah7HsheYrxQBHpkwWeAGagGeLg717eDE6S
4HaPUzYMYFBi211FzYRuJAAAp2AggwIM5ElgwJElyzowAGAUwQL7iCB4wEgnoU/hRgIJnhxUlpA
SxY8ADRQMsXDSxAdHetYIlkNDMAqJngxS47GESZ6DSiwDUNHvDd0KkhQJcIEOMlGkbhJlAK/0a8
NLDhUDdX914A+AWAkaJEOg0U/ZCgXgCGHxbAS4lXxketJcbO/aCgZi4SC34dK9CKoouxFT8cBNz
Q3K2+I/RVxXfAnIE/JTDUBC1k1S/SJATl+ltSxEcKAlJV2ALFBOTMp8f9ihVjLYUKTa8Z6GBCAF
rMN8Y8zPrZYL2oIy5RHrHr1qlOsw0AePwrsj47HFysrYpcBFcF1w8Mk2ti7wUaDRgg1EISNXVwF
lKpdsEAIj9zNAFnW3e4gecCV7Ft/qKTNP0A2Et7AUIj3ysARLDBaC7MRkF+I+x3wzA08SLiTYER
KMJ3BoR3wzUUvLdJAFBtIWIttZEQIwMzfEXNB2PZJ0J1HIrgIQkFILjBkUgSwFuJdnj3i4pEIlg
eY+Bc0AGSRxLg4zsblkcYODiK0KNzUEk1JAkaCkjDbSc+maE5d20i3HY0zDbdh1vQyWNuJkjXnJ
C/HDbCQeTVwOYHKEJJwmR/wlBYi16KMMBOHTnClZpjmpAYUh0GGoyJMxya6KcBlieIj7IsqB0ji
5iwyyu8ZboigKCd2RRVAUTQyBAugToqXDVhwKpUIxzgyoaacILMc5jQEtkIHLCjwQUMkxhnx5I/
seMBta3cKSk7BghQAQMeqMmkY20amA+zHtDiEwl10dRiBcPoacJr0qjx7Ai+yTjQvk31aws92JZ
Q1070mGsSQsS1uYWiJeDrCkGy+CZvnjFEUME7VaFaQAcXCCDyyBYA3NQGIY8ssgU7vqAxjB4EwA
DEIyxggQAsjxDBzRagKtbGaBXclAMMvNNuBaiGAAA7"

  return [image create photo -format GIF -data $logoData]
}

# create the Tk window and place it
makeWindow

# process Tk events until the window is destroyed
tkwait window .

#############################################################################
#
# This file is licensed under the Cadence Public License Version 1.0 (the
# "License"), a copy of which is found in the included file named "LICENSE",
# and is distributed "AS IS." TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE
# LAW, CADENCE DISCLAIMS ALL WARRANTIES AND IN NO EVENT SHALL BE LIABLE TO
# ANY PARTY FOR ANY DAMAGES ARISING OUT OF OR RELATING TO USE OF THIS FILE.
# Please see the License for the full text of applicable terms.
#
#############################################################################
