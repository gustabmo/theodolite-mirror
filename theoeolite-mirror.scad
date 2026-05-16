// by guexel@gmail.com Gustavo Exel
// 2025-06-14 first version (JSCAD)
// 2026-05-16 Ported to OpenSCAD by gemini

// mirror holder for Wild T2 theodolites
// 3d model suitable for a 3d printer
// you'll need a 1"=25.4mm round mirror, which you can find on temu.com

/* [Global Parameters] */
$fn = 80; // replaces 'segments'

slack = 0.1;
radClam = 16;
widClamM = 3; // clam with Mirror
widClamA = 4; // clam with Attachment
wallBottomVoid = 1;
wallAroundVoid = 1.5;
heightAttachmentCylinder = 5;
wallAttachmentCylinder = 1;
radAttachmentCylinder = 5;
heightNotch = 1;
beforeNotch = 1;
depthNotch = 0.2;
radMirror = 25.45 / 2; // for a 1"=25.4mm round mirror
widMirror = 1.5;
lenHinge = radClam * 2 * 0.6;
radHinge = 3 + slack / 2;
inwardHinge = 1.6;
radHole = 1.95 / 2; // best fit to use 1.75mm filament as axle
partsHinge = 12;

// Execute main arrangement
main();

module main() {
    clamWithMirror();
    
    // Separation offset mimicking the JSCAD translation logic
    translate([radClam * 2 + radHinge - inwardHinge + 2, 0, 0])
        clamWithAttachment(0); 
}

module hingeHole(center, evenOrOdd) {
    lenPart = lenHinge / partsHinge;
    
    translate(center)
    rotate([90, 0, 0]) // rotateX(Math.PI/2)
    union() {
        // Core axle hole through everything
        cylinder(h = lenHinge, r = radHole, center = true);
        
        // Loop to generate parts
        for (i = [0 : partsHinge - 1]) {
            z_pos = -lenHinge / 2 + lenPart / 2 + (i * lenPart);
            
            // Check condition mirroring: ((!evenOrOdd) == ((i%2)!=0))
            if ((!evenOrOdd && (i % 2 != 0)) || (evenOrOdd && (i % 2 == 0))) {
                // Diagonal cones to ease fitting the axle in
                heightDiagonal = min(radHole * 2, lenPart / 4);
                radDiagonal = min(radHole * 1.5, radHole + heightDiagonal * 0.8);
                
                // Bottom entry cone for the section
                translate([0, 0, z_pos - lenPart / 2 + heightDiagonal / 2])
                    cylinder(h = heightDiagonal, r1 = radDiagonal, r2 = radHole, center = true);
                
                // Top exit cone for the section
                translate([0, 0, z_pos + lenPart / 2 - heightDiagonal / 2])
                    cylinder(h = heightDiagonal, r1 = radHole, r2 = radDiagonal, center = true);
            } else {
                // Clearances for alternating hinge knuckles
                translate([0, 0, z_pos])
                    cylinder(h = lenPart + slack, r = radHinge + slack, center = true);
            }
        }
    }
}

module hingeCylinder(center, extraRadius = 0) {
    translate(center)
    rotate([90, 0, 0])
        cylinder(h = lenHinge, r = radHinge + extraRadius, center = true);
}

module clamWithAttachment(xis) {
    // Math equivalents adjusted for base center transformations
    centerClam = [xis + radClam, 0, 0];
    centerHinge = [centerClam[0] + radClam - inwardHinge, centerClam[1], centerClam[2] - widClamA / 2 - slack / 2];
    
    elevate = -(centerHinge[2] - radHinge);
    adjCenterClam = [centerClam[0], centerClam[1], centerClam[2] + elevate];
    adjCenterHinge = [centerHinge[0], centerHinge[1], centerHinge[2] + elevate];
    
    centerAttachmentCylinder = [adjCenterClam[0], adjCenterClam[1], adjCenterClam[2] - widClamA / 2 + heightAttachmentCylinder / 2];
    centerNotch = [centerAttachmentCylinder[0], centerAttachmentCylinder[1], centerAttachmentCylinder[2] + heightAttachmentCylinder / 2 - beforeNotch - heightNotch / 2];

    // OpenSCAD doesn't have an automated 'measureBoundingBox' function, 
    // but the geometry structure mirrors face down behavior explicitly:
    // rotateX(PI) then align bottom to Z=0.
    
    translate([0, 0, adjCenterClam[2] + widClamA / 2]) // Re-adjusting Z to sit clean at 0 after inversion
    rotate([180, 0, 0]) 
    difference() {
        union() {
            difference() {
                // Base Clam
                translate(adjCenterClam)
                    cylinder(h = widClamA, r = radClam, center = true);
                
                // Cut away anything past the hinge line
                translate([adjCenterHinge[0] + radHinge / 2 - slack / 2, adjCenterClam[1], adjCenterClam[2]])
                    cube([radHinge, radClam * 2, widClamA + 0.1], center = true);
                
                // Hollowing out the main chamber
                difference() {
                    translate([adjCenterClam[0], adjCenterClam[1], adjCenterClam[2] + wallBottomVoid / 2])
                        cylinder(h = widClamA - wallBottomVoid, r = radClam - wallAroundVoid, center = true);
                    
                    hingeCylinder(adjCenterHinge, wallAroundVoid + slack);
                }
            }
            
            // Physical hinge solid outer core
            hingeCylinder(adjCenterHinge);
            
            // Mounting Attachment stalk
            translate(centerAttachmentCylinder)
                cylinder(h = heightAttachmentCylinder, r = radAttachmentCylinder, center = true);
        }
        
        // Pin hole drill tool
        hingeHole(adjCenterHinge, false);
        
        // Core hole inside mounting attachment
        translate(centerAttachmentCylinder)
            cylinder(h = heightAttachmentCylinder + 0.1, r = radAttachmentCylinder - wallAttachmentCylinder, center = true);
        
        // Locking retention notch pattern
        translate(centerNotch)
            difference() {
                cylinder(h = heightNotch + 0.05, r = radAttachmentCylinder + 0.05, center = true);
                cylinder(h = heightNotch + 0.1, r = radAttachmentCylinder - depthNotch, center = true);
            }
    }
}

module clamWithMirror() {
    centerHinge = [radClam * 2 - inwardHinge, 0, widClamM + slack / 2];
    
    difference() {
        union() {
            difference() {
                // Base Clam Mirror Base Plate
                translate([radClam, 0, widClamM / 2])
                    cylinder(h = widClamM, r = radClam, center = true);
                
                // Mirror Recess Pocket
                translate([1 + radMirror, 0, widClamM - widMirror / 2])
                    cylinder(h = widMirror + 0.01, r = radMirror, center = true);
                
                // Rear Clearance Flat Cut
                translate([centerHinge[0] + radHinge / 2 - slack / 2, 0, widClamM / 2])
                    cube([radHinge, radClam * 2, widClamM + 0.1], center = true);
            }
            // Hinge Solid Structure
            hingeCylinder(centerHinge);
        }
        // Interlocking Alternating Axle channels
        hingeHole(centerHinge, true);
    }
}
