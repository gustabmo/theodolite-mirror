// by guexel@gmail.com Gustavo Exel
// 2025-06-14 first version

// mirror holder for Wild T2 theodolites
// 3d model suitable for a 3d printer
// should be run on jscad then exported to a 3d printable format such as .stl
// you'll need a 1"=25.4mm round mirror, which you can find on temu.com

// made for https://github.com/jscad/
// should work on openjscad.xyz and jscad.app
// doesn't work on neorama.de/openjscad.org which apparently uses an old version of JSCad


// jscad needs this
"use strict"
const jscad = require('@jscad/modeling')
const { intersect, subtract, union } = jscad.booleans
const { colorize } = jscad.colors
const { cube, sphere, cylinder, cuboid, cylinderElliptic } = jscad.primitives
const { rotate, rotateX, translate } = jscad.transforms


let segments = 80;

let slack = 0.1;

let radClam = 16;
let widClamM = 3; // clam with Mirror
let widClamA = 4; // clam with Attachment
let wallBottomVoid = 1;
let wallAroundVoid = 1.5;
let heightAttachmentCylinder = 5;
let wallAttachmentCylinder = 1;
let radAttachmentCylinder = 5;
let heightNotch = 1;
let beforeNotch = 1;
let depthNotch = 0.2;
let radMirror = 25.4/2;
let widMirror = 1.5;
let lenHinge = radClam*2*0.6;
let radHinge = 3+slack/2;
let inwardHinge = 1.6;
let radHole = 1.75/2; // to use the printer's filament as the axle
let partsHinge = 12;


function hingeHole(center,evenOrOdd) {
	let lenPart = lenHinge/partsHinge;
	let centerPart = [0,0,-lenHinge/2+lenPart/2];

	// diagonal cone to ease fitting the axle in
	let heightDiagonal = Math.min ( radHole * 2, lenPart/4 ); 
	let radDiagonal = Math.min ( radHole*1.5, radHole+heightDiagonal*0.8 );

	let ret = cylinder({height:lenHinge,radius:radHole}); // starts with the axle hole
	for ( let i = 0; i < partsHinge; i++) {
		if ((!evenOrOdd) == ((i%2)!=0)) {
			ret = union ( ret,
				// diagonal cone at each end to ease fitting the axle in
				cylinderElliptic ({ 
					height:heightDiagonal,
					startRadius:[radDiagonal,radDiagonal],
					endRadius:[radHole,radHole],
					center:[centerPart[0],centerPart[1],centerPart[2]-lenPart/2+heightDiagonal/2],
					segments:segments
				}), 
				cylinderElliptic ({
					height:heightDiagonal,
					startRadius:[radHole,radHole],
					endRadius:[radDiagonal,radDiagonal],
					center:[centerPart[0],centerPart[1],centerPart[2]+lenPart/2-heightDiagonal/2],
					segments:segments
				}) 
			);
		} else {
			ret = union ( ret,
				cylinder ({
					center:centerPart,
					radius:radHinge+slack,
					height:lenPart+slack,
					segments:segments
				})
			);
		}
		centerPart[2] += lenPart;
	}
	return translate (
        center,
		rotateX(Math.PI/2,ret)
	);
}


function hingeCylinder(center,extraRadius=0) {
	return translate (
        center,
        rotateX (
			Math.PI/2,
			cylinder ({
				height: lenHinge,
				radius: radHinge + extraRadius,
				segments:segments
			})
        )
    );
}


function clamWithAttachment (xis) {
	// start without worrying about the z position
	let centerClam = [xis+radClam,0,0];
	let centerHinge = [
		centerClam[0]+radClam-inwardHinge,
		centerClam[1],
		centerClam[2]-widClamA/2-slack/2
	];
	// then adjust so the hing touches z=0
	let elevate = - (centerHinge[2]-radHinge);
	centerClam[2] += elevate;
	centerHinge[2] += elevate;
	// other variables
	let centerAttachmentCylinder = [
		centerClam[0],
		centerClam[1],
		centerClam[2]-widClamA/2+heightAttachmentCylinder/2
	];
	let centerNotch = [
		centerAttachmentCylinder[0],
		centerAttachmentCylinder[1],
		(
			centerAttachmentCylinder[2]
			+heightAttachmentCylinder/2
			-beforeNotch
			-heightNotch/2
		)
	];

	return subtract (
		union (
			subtract(
				cylinder ({ // clam
				 	center:centerClam,
					radius:radClam,
					height:widClamA,
					segments:segments
				}),
				cuboid ({ // whatever's further away than the hinge
					size:[radHinge,radClam*2,widClamA],
					center:[
						centerHinge[0]+radHinge/2-slack/2,
						centerClam[1],
						centerClam[2]
					]			
				}),
				subtract (
					cylinder ({ // void inside the clam
						center:[
							centerClam[0],
							centerClam[1],
							centerClam[2]+wallBottomVoid/2
						],
						radius:radClam-wallAroundVoid,
						height:widClamA-wallBottomVoid,
						segments:segments
					}),
					hingeCylinder( // don't void what touches the hinge
						centerHinge,
						wallAroundVoid+slack
					) 
				)
			),
			hingeCylinder(centerHinge),
			cylinder ({ // attachment cylinder
				center:centerAttachmentCylinder,
				radius:radAttachmentCylinder,
				height:heightAttachmentCylinder
			})
		),
		hingeHole(centerHinge,false),
		cylinder({ // attachment cylinder hole
			center:centerAttachmentCylinder,
			radius:radAttachmentCylinder-wallAttachmentCylinder,
			height:heightAttachmentCylinder
		}),
		subtract( //notch
			cylinder ({ 
				center:centerNotch,
				radius:radAttachmentCylinder,
				height:heightNotch
			}),
			cylinder ({ 
				center:centerNotch,
				radius:radAttachmentCylinder-depthNotch,
				height:heightNotch
			})
		)
	);
} // clamWithAttachment()


function clamWithMirror () {
	let centerHinge = [radClam*2-inwardHinge,0,widClamM+slack/2];
    //return hingeHole(centerHinge);
	return subtract (
		union (
			subtract(
				cylinder ({ // clam
				 	center:[radClam,0,widClamM/2],
					radius:radClam,
					height:widClamM,
					segments:segments
				}),
				cylinder ({ // space for the mirror
					center: [1+radMirror,0,widClamM-widMirror/2],
					radius:radMirror,
					height:widMirror,
					segments:segments
				}),
				cuboid ({ // whatever's further away than the hinge
					size:[radHinge,radClam*2,widClamM],
					center:[centerHinge[0]+radHinge/2-slack/2,0,widClamM/2]			
				})
			),
			hingeCylinder(centerHinge)
		),
		hingeHole(centerHinge,true)
	);
} // clamWithMirror()



function main() {
	return [
		clamWithMirror(),
		clamWithAttachment(radClam*2+radHinge*2)
	];
}


// jscad needs this
module.exports = { main }
