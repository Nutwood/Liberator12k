use <../Components/Teardrop.scad>;

module RoundedBoolean(edgeOffset=1, edgeSign=-1,
                      r=0.25,
                      teardrop=false, teardropAngle=-90) {
  difference() {
    translate([edgeOffset-r,-r])
    square([r*2, r*2]);
    
    translate([edgeOffset+(edgeSign*r),r]) {
      if (teardrop){
        rotate(teardropAngle)
        Teardrop(r=r);
      } else {
        circle(r=r);
      }
    }
  }
  
}

module HoleChamfer(r1=0.5, r2=0.125, teardrop=false) {
  rotate_extrude()
  RoundedBoolean(r=r2,
                 edgeOffset=r1,
                 edgeSign=1,
                 teardrop=teardrop);
}

module ChamferedSquare(xy=[1,1], r=0.25, teardrop=true, teardropTruncated=true, $fn=40) {
  hull()
  for (mX = [r,xy[0]-r]) {
    // Top Circle
    translate([mX, xy[1]-r])
    circle(r);
    
    // Bottom
    translate([mX, r])
    if (teardrop){
      rotate(-90)
      Teardrop(r, truncated=teardropTruncated, $fn=$fn);
    } else {
      circle(r);
    }
  }
    
}

module ChamferedCube(xyz=[1,1,1], r=0.25, fn=20) {
  intersection() {
    linear_extrude(height=xyz[2])
    ChamferedSquare(teardrop=false, $fn=fn);
    
    rotate([90,0,90])
    linear_extrude(height=xyz[2])
    ChamferedSquare($fn=fn);
    
    mirror([0,1,0])
    rotate([90,0,0])
    linear_extrude(height=xyz[2])
    ChamferedSquare($fn=fn);
  }
}


module CylinderChamfer(r1=1, r2=0.25, teardrop=false) {
  rotate_extrude()
  RoundedBoolean(r=r2,
                 edgeOffset=r1,
                 edgeSign=-1,
                 teardrop=teardrop);
}

module CylinderChamferEnds(r1=1, r2=0.25, h=1, $fn=40) {
  render() {
    
    // Keep the bottom teardropped for printing
    CylinderChamfer(r1=r1, r2=r2, teardrop=true);
    
    // We can round the top over
    translate([0,0,h])
    mirror([0,0,1])
    CylinderChamfer(r1=r1, r2=r2, teardrop=false);
  }
}


module ChamferedCylinder(r1=1, r2=0.25, h=1, $fn=40) {
  render()
  difference() {
    cylinder(r=r1, h=h);
    CylinderChamferEnds(r1=r1, r2=r2, h=h);
  }
}

translate([0,2,0])
ChamferedSquare(xy=[1,2]);

translate([-3,0,0])
ChamferedCube();

HoleChamfer($fn=20);

RoundedBoolean(teardrop=true, $fn=20);

// Chamfered Cylinder
translate([3,0,0])
ChamferedCylinder(r1=1, r2=0.25, h=1, $fn=40);