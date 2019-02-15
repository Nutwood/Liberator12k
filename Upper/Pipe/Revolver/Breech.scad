include <../../../Meta/Animation.scad>;

use <../../../Meta/Manifold.scad>;
use <../../../Meta/Units.scad>;
use <../../../Meta/Debug.scad>;
use <../../../Meta/Resolution.scad>;

use <../../../Finishing/Chamfer.scad>;
use <../../../Shapes/Semicircle.scad>;
use <../../../Shapes/Teardrop.scad>;

use <../../../Components/Firing Pin.scad>;
use <../../../Components/Cylinder Redux.scad>;
use <../../../Components/Pipe/Cap.scad>;
use <../../../Components/Pipe/Lugs.scad>;

use <../../../Vitamins/Nuts And Bolts.scad>;
use <../../../Vitamins/Pipe.scad>;
use <../../../Vitamins/Rod.scad>;

use <../../../Lower/Receiver Lugs.scad>;
use <../../../Lower/Trigger.scad>;
use <../../../Lower/Lower.scad>;

use <../Linear Hammer.scad>;
use <../Frame.scad>;
use <../Pipe Upper.scad>;


DEFAULT_SPINDLE_OFFSET=1.355;
DEFAULT_CHARGER_TRAVEL = 2.65;//(LowerMaxX()+SearRadius()+0.5);
DEFAULT_CHARGING_ROD_LENGTH = LowerMaxX()+SearRadius()+DEFAULT_CHARGER_TRAVEL;

// Measured: Vitamins
function BreechPlateThickness() = 1/4;
function BreechPlateWidth() = 1.5;

// Settings: Lengths
function BreechBoltRearExtension() = 3.5;

// Settings: Walls
function WallBreechBolt() = 0.1875;
function WallChargingPin() = 1/4;

// Settings: Positions
function BreechFrontX() = 0;
function BreechRearX()  = BreechFrontX()-0.5;

// Settings: Vitamins
function BreechBolt() = Spec_BoltOneHalf();
function BreechBolt() = Spec_BoltThreeEighths();
function BreechBolt() = Spec_BoltFiveSixteenths();
function ChargingRod() = Spec_RodOneQuarterInch();
function PinSpec() = Spec_RodThreeThirtysecondInch();
function SquareRodFixingBolt() = Spec_BoltM3();

// Calculated: Positions
function BreechBoltOffsetZ() = ReceiverOR()
                            + BreechBoltRadius()
                            + WallBreechBolt();
function BreechBoltOffsetY() = 1
                             - BreechBoltRadius()
                             - WallBreechBolt();
function BreechPlateHeight(spindleOffset=1)
                           = BreechBoltOffsetZ()
                           + BreechBoltRadius()
                           + spindleOffset
                           + RodRadius(CylinderRod())
                           + (2*WallBreechBolt());
function BreechTopZ() = BreechBoltOffsetZ()
                           + WallBreechBolt()
                           + BreechBoltRadius();
function FiringPinMinX() = BreechRearX()-FiringPinBodyLength();


function ChargingRodOffset() = ReceiverOR()+RodRadius(ChargingRod())+0.0625;
function ChargingPinX() = BreechRearX()-0.125;
function ChargingRodMinX() = ChargingPinX()-WallChargingPin();

function WallChargingToggle() = 0.125;
function ChargingToggleOffsetZ() = ChargingRodOffset()-(RodRadius(ChargingRod())*2);
function ChargingToggleMaxX() = BreechRearX()-0.375;
function ChargingToggleMinX() = FiringPinMinX()-LinearHammerTravel()+WallChargingToggle()-0.25;
function ChargingToggleTotalLength() = ChargingToggleMaxX()-ChargingToggleMinX();
function ChargingToggleFrontLinkLength() = 0.75;
function ChargingToggleRearLinkLength() = 1.0;
function ChargerLinkWidth() = 1/8;
function ChargerLinkHeight() = 1/2;

echo ("ChargingToggleTotalLength", ChargingToggleTotalLength());


function ChargingToggleFactor() = SubAnimate(ANIMATION_STEP_CHARGE, start=0.0, end=0.2)
                                - SubAnimate(ANIMATION_STEP_CHARGER_RESET, start=0.90, end=1);

function HammerFactor() = Animate(ANIMATION_STEP_FIRE)
                        - SubAnimate(ANIMATION_STEP_CHARGE, start=0.0, end=0.2);

// Shorthand: Measurements
function BreechBoltRadius(clearance=false)
    = BoltRadius(BreechBolt(), clearance);

function BreechBoltDiameter(clearance=false)
    = BoltDiameter(BreechBolt(), clearance);

module ChargingRod(clearance=RodClearanceLoose(),
                   length=LowerMaxX()+SearRadius()+DEFAULT_CHARGER_TRAVEL,
                   bolt=true, actuator=true,
                   travel=DEFAULT_CHARGER_TRAVEL,
                   animationFactor=0,
                   cutter=false, debug=false) {

  translate([-travel*animationFactor,0,0]) {
    
    if (!cutter) {
      
      color("Silver")
      translate([ChargingPinX(), 0, ChargingRodOffset()])
      hull() {
        rotate([90,0,0])
        Rod(PinSpec(), length=0.76, center=true, clearance=cutter?clearance:undef);

        if (cutter) {
          translate([-travel,0,0])
          rotate([90,0,0])
          Rod(PinSpec(), length=0.76, center=true, clearance=cutter?clearance:undef);
        }
      }
    }

    color("SteelBlue") DebugHalf(enabled=debug) {

      // Charging rod
      translate([ChargingRodMinX()-(cutter?travel:0),0,ChargingRodOffset()])
      rotate([0,90,0])
      SquareRod(ChargingRod(), length=length+(cutter?travel:0)+ManifoldGap(),
                clearance=cutter?clearance:undef);

      // Charging Rod Fixing Bolt
      if (bolt)
      translate([ChargingRodMinX()+length-0.5,0,BreechTopZ()])
      Bolt(bolt=SquareRodFixingBolt(), capOrientation=true,
           length=cutter?BreechTopZ():1, clearance=cutter, teardrop=cutter);

      // Actuator rod
      if (actuator)
      translate([travel+(ZigZagWidth()/2),0,ChargingRodOffset()-RodRadius(ChargingRod())])
      mirror([0,0,1])
      hull() {
        Rod(ActuatorRod(), clearance=cutter?RodClearanceSnug():undef,
            length=0.49);

        if (cutter) {
          translate([-travel-ZigZagWidth(),0,0])
          Rod(ActuatorRod(), clearance=cutter?RodClearanceLoose():undef,
              length=0.49);
        }
      }
    }
  }
}

module ChargingToggle(angle=70, toggleAngle=-10, factor=ChargingToggleFactor(),
                      cutter=false, $fn=20) {
  
  /*
  
function WallChargingToggle() = 0.25;
function ChargingToggleMaxX() = BreechRearX()-WallChargingToggle();
function ChargingToggleMinX() = FiringPinMinX()-LinearHammerTravel()-0.25+WallChargingToggle();
function ChargingToggleTotalLength() = ChargingToggleMaxX()-ChargingToggleMinX();
function ChargingToggleLinkLength() = ChargingToggleTotalLength()/2;
echo ("ChargingToggleTotalLength", ChargingToggleTotalLength());
*/
  
  
  translate([ChargingToggleMaxX(),0,ChargingToggleOffsetZ()])
  rotate([0,0,0]) {
    
    
    rotate([0,(angle)*(1-factor),0])
    for (X = [0, ChargingToggleFrontLinkLength()]) rotate([0,toggleAngle,0]) translate([-X,0,0])
    rotate([90,0,0])
    Rod(PinSpec(), length=0.76, center=true, clearance=cutter?RodClearanceLoose():undef);
    
    // Front link
    color("Yellow")
    rotate([0,(angle)*(1-factor),0])
    rotate([0,toggleAngle,0])      
    rotate([90,0,0])
    render()
    difference() {
      linear_extrude(height=0.25, center=true) {
        
        // Front pivot point
        *circle(r=WallChargingToggle());
        
        // Linkage bar
        translate([0.125,-RodRadius(ChargingRod())])
        mirror([1,0])
        square([ChargingToggleFrontLinkLength()+0.25, RodDiameter(ChargingRod())]);
        
        // Reset Trip
        *rotate(angle+toggleAngle-20)
        polygon([[-WallChargingToggle(),0],
                 [WallChargingToggle(),0],
                 [WallChargingToggle(),0.4375],
                 //[WallChargingToggle()/2,0.625]
        ]);
        
        // Knee pivot
        *translate([-ChargingToggleFrontLinkLength(),0])
        circle(r=WallChargingToggle());
      }
    }
    
    
    // Rear link
    rotate([0,(angle)*(1-factor),0])
    rotate([0,toggleAngle,0])
    translate([-ChargingToggleFrontLinkLength(),0,0])
    rotate([90,0,0])
    rotate((-angle*2)*(factor))
    rotate((angle+toggleAngle)*2)
    color("Green") render()
    linear_extrude(height=0.26, center=true)      
    union() {
      
      // Knee pivot
      *circle(r=WallChargingToggle());
      
      translate([-ChargingToggleRearLinkLength(),0]) {
        
        // Linkage bar
        translate([-0.125,-RodRadius(ChargingRod())])
        square([ChargingToggleRearLinkLength()+0.25, RodDiameter(ChargingRod())]);
        
        //rotate(-angle-toggleAngle)
        *translate([0,WallChargingToggle()*2])
        circle(r=WallChargingToggle());
        
        // Rear pivot point
        circle(r=0.125);
      }
    }
  }
  
}

module BreechFiringPinAssembly(template=false,
         cutter=false, debug=false) {
  translate([BreechRearX(),0,0])
  rotate([0,-90,0])
  FiringPinAssembly(cutter=cutter, debug=debug, template=template);
}

module BreechPlate(cutter=false, debug=false,
                   spindleOffset=DEFAULT_SPINDLE_OFFSET) {
  color("LightSteelBlue")
  DebugHalf(enabled=debug)
  difference() {
    translate([-BreechPlateThickness(), -1-ManifoldGap(2), -BreechPlateWidth()/2])
    ChamferedCube([BreechPlateThickness()+(cutter?(1/8):ManifoldGap(2)),
                   2+ManifoldGap(4),
                   BreechPlateWidth()],
                  r=1/32,
                  chamferXYZ=[0,1,0],
                  teardropXYZ=[false, false, false],
                  teardropTopXYZ=[false, false, false]);
    
    if (!cutter) {
      BreechFiringPinAssembly(cutter=true);
    }
  }
}

module Breech(debug=false, chargingRodLength=LowerMaxX()+SearRadius(),
              spindleOffset=DEFAULT_SPINDLE_OFFSET,
              alpha=0.5) {
  color("LightSteelBlue", alpha)
  DebugHalf(enabled=debug)
  difference() {
    union() {
      translate([BreechFrontX(),0,0])
      translate([BreechRearX(),
                 -1,
                 BreechBoltOffsetZ()+BreechBoltRadius()+WallBreechBolt()])
      mirror([0,0,1])
      ChamferedCube([BreechFrontX()-BreechRearX(),
                     2,
                     BreechPlateHeight(spindleOffset)],
                    r=1/16);

      children();
    }
    
    BreechPlate(cutter=true);

    BreechFiringPinAssembly(cutter=true);

    BreechBolts(cutter=true);

    translate([BreechRearX()-LowerMaxX(),0,0])
    FrameBolts(cutter=true);
    
    ChargingRod(length=chargingRodLength, cutter=true, actuator=false, pin=false);

  }
}

module BreechBoltIterator() {
    for (Y = [BreechBoltOffsetY(),-BreechBoltOffsetY()])
    translate([BreechRearX()-BreechBoltRearExtension()-ManifoldGap(), Y, BreechBoltOffsetZ()])
    rotate([0,90,0])
    children();
}

module BreechBolts(length=abs(BreechRearX())+BreechBoltRearExtension(),
              debug=false, cutter=false, alpha=1) {

  color("Silver", alpha)
  DebugHalf(enabled=debug) {
    BreechBoltIterator()
    NutAndBolt(bolt=BreechBolt(), boltLength=length+ManifoldGap(2),
         capHex=true, clearance=cutter);
  }
}

module FrameSupport(length=2.5, width=0.125+0.01,
                    height=3/4, wall=1/8,
                    clearance=0.01, debug=false, alpha=1) {
  color("Purple", alpha)
  DebugHalf(enabled=debug)
  for (M = [0,1]) mirror([0,M,0])
  translate([0,-1-width-wall,BreechTopZ()-wall-height])
  difference() {
    ChamferedCube([length, width+(wall*3), height+(wall*2)], r=1/16);
    
    translate([wall, wall-clearance,wall-clearance])
    cube([length, width+(wall*2)+clearance+ManifoldGap(), height+(clearance*2)]);
    
    translate([0, width+wall,-ManifoldGap()])
    cube([length, (wall*2)+ManifoldGap(), height+wall+clearance]);
  }
}

module FrameSupportRear(debug=false, alpha=1) {
  translate([BreechRearX()-BreechBoltRearExtension()+0.3,0,0])
  FrameSupport(debug=debug, alpha=alpha);
}

module BreechAssembly(breechBoltLength=abs(BreechRearX())+BreechBoltRearExtension(),
                      breechBoltAlpha=0.3,
                      showBreech=true,
                      chargingRodAnimationFactor=Animate(ANIMATION_STEP_CHARGE)
                             - Animate(ANIMATION_STEP_CHARGER_RESET),
                      chargingRodLength=DEFAULT_CHARGING_ROD_LENGTH,
                      chargingRodTravel=DEFAULT_CHARGER_TRAVEL,
                      hammerTravelFactor=HammerFactor(),
                      debug=false) {
  BreechFiringPinAssembly(breechBoltLength=breechBoltLength, debug=false);

  ChargingRod(length=chargingRodLength,
              travel=chargingRodTravel,
              animationFactor=chargingRodAnimationFactor, cutter=false);

  *ChargingToggle();

  translate([BreechRearX()-LowerMaxX(),0,0])
  FrameBolts(debug=debug);
                        
  *FrameSupportRear(debug=debug);
  
  BreechPlate(debug=debug);
  
  if (showBreech)
  Breech(debug=debug)
  children();
  
  BreechBolts(length=breechBoltLength, debug=debug, alpha=breechBoltAlpha);

  translate([FiringPinMinX()-LinearHammerTravel(),0,0])
  LinearHammerAssembly(travelFactor=hammerTravelFactor);
}


BreechAssembly(debug=true);

translate([BreechRearX(),0,0])
PipeUpperAssembly(pipeAlpha=0.3,
                  receiverLength=12,
                  chargingHandle=false,
                  frameUpper=false,
                  stock=true, tailcap=false, lower=true,
                  debug=false);
$t=AnimationDebug(ANIMATION_STEP_CHARGE, T=$t, start=0, end=0.5);
//$t=AnimationDebug(ANIMATION_STEP_CHARGER_RESET, T=$t, start=0.9);

*!scale(25.4)
for (M = [0,1]) mirror([0,M,0])
rotate([90,0,0])
translate([0,1.25,-BreechTopZ()-0.1875])
FrameSupport(debug=true);


*!scale(25.4)
difference() {
  translate([-1,-1-0.25-ManifoldGap(),-0.25])
  cube([2, 2+0.25, 0.25]);
  
  rotate([0,90,0])
  BreechPlate(cutter=true);
  
  rotate([0,-90,0])
  BreechFiringPinAssembly(template=true);
}