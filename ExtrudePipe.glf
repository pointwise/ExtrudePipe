#
# Copyright 2009 (c) Pointwise, Inc.
# All rights reserved.
# 
# This sample Pointwise script is not supported by Pointwise, Inc.
# It is provided freely for demonstration purposes only.  
# SEE THE WARRANTY DISCLAIMER AT THE BOTTOM OF THIS FILE.
#

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

  pack [label .buttons.logo -image [pwLogo] -bd 0 -relief flat] \
      -side left -padx 5

  bind . <KeyPress-Escape> { .buttons.cancel invoke }
  bind . <Control-KeyPress-Return> { .buttons.ok invoke }
}

proc pwLogo {} {
  set logoData "
R0lGODlheAAYAIcAAAAAAAICAgUFBQkJCQwMDBERERUVFRkZGRwcHCEhISYmJisrKy0tLTIyMjQ0
NDk5OT09PUFBQUVFRUpKSk1NTVFRUVRUVFpaWlxcXGBgYGVlZWlpaW1tbXFxcXR0dHp6en5+fgBi
qQNkqQVkqQdnrApmpgpnqgpprA5prBFrrRNtrhZvsBhwrxdxsBlxsSJ2syJ3tCR2siZ5tSh6tix8
ti5+uTF+ujCAuDODvjaDvDuGujiFvT6Fuj2HvTyIvkGKvkWJu0yUv2mQrEOKwEWNwkaPxEiNwUqR
xk6Sw06SxU6Uxk+RyVKTxlCUwFKVxVWUwlWWxlKXyFOVzFWWyFaYyFmYx16bwlmZyVicyF2ayFyb
zF2cyV2cz2GaxGSex2GdymGezGOgzGSgyGWgzmihzWmkz22iymyizGmj0Gqk0m2l0HWqz3asznqn
ynuszXKp0XKq1nWp0Xaq1Hes0Xat1Hmt1Xyt0Huw1Xux2IGBgYWFhYqKio6Ojo6Xn5CQkJWVlZiY
mJycnKCgoKCioqKioqSkpKampqmpqaurq62trbGxsbKysrW1tbi4uLq6ur29vYCu0YixzYOw14G0
1oaz14e114K124O03YWz2Ie12oW13Im10o621Ii22oi23Iy32oq52Y252Y+73ZS51Ze81JC625G7
3JG825K83Je72pW93Zq92Zi/35G+4aC90qG+15bA3ZnA3Z7A2pjA4Z/E4qLA2KDF3qTA2qTE3avF
36zG3rLM3aPF4qfJ5KzJ4LPL5LLM5LTO4rbN5bLR6LTR6LXQ6r3T5L3V6cLCwsTExMbGxsvLy8/P
z9HR0dXV1dbW1tjY2Nra2tzc3N7e3sDW5sHV6cTY6MnZ79De7dTg6dTh69Xi7dbj7tni793m7tXj
8Nbk9tjl9N3m9N/p9eHh4eTk5Obm5ujo6Orq6u3t7e7u7uDp8efs8uXs+Ozv8+3z9vDw8PLy8vL0
9/b29vb5+/f6+/j4+Pn6+/r6+vr6/Pn8/fr8/Pv9/vz8/P7+/gAAACH5BAMAAP8ALAAAAAB4ABgA
AAj/AP8JHEiwoMGDCBMqXMiwocOHECNKnEixosWLGDNqZCioo0dC0Q7Sy2btlitisrjpK4io4yF/
yjzKRIZPIDSZOAUVmubxGUF88Aj2K+TxnKKOhfoJdOSxXEF1OXHCi5fnTx5oBgFo3QogwAalAv1V
yyUqFCtVZ2DZceOOIAKtB/pp4Mo1waN/gOjSJXBugFYJBBflIYhsq4F5DLQSmCcwwVZlBZvppQtt
D6M8gUBknQxA879+kXixwtauXbhheFph6dSmnsC3AOLO5TygWV7OAAj8u6A1QEiBEg4PnA2gw7/E
uRn3M7C1WWTcWqHlScahkJ7NkwnE80dqFiVw/Pz5/xMn7MsZLzUsvXoNVy50C7c56y6s1YPNAAAC
CYxXoLdP5IsJtMBWjDwHHTSJ/AENIHsYJMCDD+K31SPymEFLKNeM880xxXxCxhxoUKFJDNv8A5ts
W0EowFYFBFLAizDGmMA//iAnXAdaLaCUIVtFIBCAjP2Do1YNBCnQMwgkqeSSCEjzzyJ/BFJTQfNU
WSU6/Wk1yChjlJKJLcfEgsoaY0ARigxjgKEFJPec6J5WzFQJDwS9xdPQH1sR4k8DWzXijwRbHfKj
YkFO45dWFoCVUTqMMgrNoQD08ckPsaixBRxPKFEDEbEMAYYTSGQRxzpuEueTQBlshc5A6pjj6pQD
wf9DgFYP+MPHVhKQs2Js9gya3EB7cMWBPwL1A8+xyCYLD7EKQSfEF1uMEcsXTiThQhmszBCGC7G0
QAUT1JS61an/pKrVqsBttYxBxDGjzqxd8abVBwMBOZA/xHUmUDQB9OvvvwGYsxBuCNRSxidOwFCH
J5dMgcYJUKjQCwlahDHEL+JqRa65AKD7D6BarVsQM1tpgK9eAjjpa4D3esBVgdFAB4DAzXImiDY5
vCFHESko4cMKSJwAxhgzFLFDHEUYkzEAG6s6EMgAiFzQA4rBIxldExBkr1AcJzBPzNDRnFCKBpTd
gCD/cKKKDFuYQoQVNhhBBSY9TBHCFVW4UMkuSzf/fe7T6h4kyFZ/+BMBXYpoTahB8yiwlSFgdzXA
5JQPIDZCW1FgkDVxgGKCFCywEUQaKNitRA5UXHGFHN30PRDHHkMtNUHzMAcAA/4gwhUCsB63uEF+
bMVB5BVMtFXWBfljBhhgbCFCEyI4EcIRL4ChRgh36LBJPq6j6nS6ISPkslY0wQbAYIr/ahCeWg2f
ufFaIV8QNpeMMAkVlSyRiRNb0DFCFlu4wSlWYaL2mOp13/tY4A7CL63cRQ9aEYBT0seyfsQjHedg
xAG24ofITaBRIGTW2OJ3EH7o4gtfCIETRBAFEYRgC06YAw3CkIqVdK9cCZRdQgCVAKWYwy/FK4i9
3TYQIboE4BmR6wrABBCUmgFAfgXZRxfs4ARPPCEOZJjCHVxABFAA4R3sic2bmIbAv4EvaglJBACu
IxAMAKARBrFXvrhiAX8kEWVNHOETE+IPbzyBCD8oQRZwwIVOyAAXrgkjijRWxo4BLnwIwUcCJvgP
ZShAUfVa3Bz/EpQ70oWJC2mAKDmwEHYAIxhikAQPeOCLdRTEAhGIQKL0IMoGTGMgIBClA9QxkA3U
0hkKgcy9HHEQDcRyAr0ChAWWucwNMIJZ5KilNGvpADtt5JrYzKY2t8nNbnrzm+B8SEAAADs="

  return [image create photo -format GIF -data $logoData]
}

# create the Tk window and place it
makeWindow

# process Tk events until the window is destroyed
tkwait window .

#
# DISCLAIMER:
# TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, POINTWISE DISCLAIMS
# ALL WARRANTIES, EITHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED
# TO, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE, WITH REGARD TO THIS SCRIPT.  TO THE MAXIMUM EXTENT PERMITTED 
# BY APPLICABLE LAW, IN NO EVENT SHALL POINTWISE BE LIABLE TO ANY PARTY 
# FOR ANY SPECIAL, INCIDENTAL, INDIRECT, OR CONSEQUENTIAL DAMAGES 
# WHATSOEVER (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF 
# BUSINESS INFORMATION, OR ANY OTHER PECUNIARY LOSS) ARISING OUT OF THE 
# USE OF OR INABILITY TO USE THIS SCRIPT EVEN IF POINTWISE HAS BEEN 
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGES AND REGARDLESS OF THE 
# FAULT OR NEGLIGENCE OF POINTWISE.
#
