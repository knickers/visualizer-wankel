use <publicDomainGearV1.5_stone.scad>

// Distance between the stepper motor screws
Motor_Size = 31; // [20:0.1:50]

// Diameter inside the motor screw holes
Mounting_Tab_Size = 6.15; // [4.5:0.01:7.5]

// Motor mount tab radius
Mount_Tab_R = Mounting_Tab_Size / 2;

// Must be an even number
Stator_Gear_Teeth = 8; // [4:2:12]

// Thickness of the engine
Thickness = 4; // [1:0.1:20]

// Space between moving parts
Clearance = 0.3; // [0.00:0.01:1]

assert(Stator_Gear_Teeth%2==0, "Stator gear teeth must be an even number.");

/*
Given the above parameters, we can determine the rest of the rotor and housing
geometry. Eccentricity is the offset distance of the crank (the crank is also
known as the "eccentric"). Eccentricity is also the difference in pitch radii
of the two gears.
*/

//$fn = $preview ? 60 : 80; // facet number
$fa = $preview ? 10 : 1;    // facet angle
$fs = $preview ? 2 : 0.75; // facet size

ALPHA = 360 * $t; // for animation
SQRT2 = sqrt(2);
SIN60 = sin(60);

Rotor_Radius = Motor_Size * 0.64;
Rotor_Gear_Teeth = 3/2 * Stator_Gear_Teeth;
Rotor_Gear_Pitch_Radius = Rotor_Radius / 2; // Pitch radius
Tooth_Size = 2 * PI * Rotor_Gear_Pitch_Radius / Rotor_Gear_Teeth;
Rotor_Gear_Outer_Radius = Tooth_Size*Rotor_Gear_Teeth/PI/2 + Tooth_Size/2;
ECC = Rotor_Gear_Pitch_Radius / 3;
Eccentric_Radius = Rotor_Gear_Outer_Radius - 0.5;
Flatness = Motor_Size; // Bulge of the rotor
Hole_Radius = 0.5 * Tooth_Size * Stator_Gear_Teeth / PI / 2;
Hole_Diameter = Hole_Radius*2;

echo(
	ECC=ECC,
	Motor_Size=Motor_Size,
	Rotor_Radius=Rotor_Radius,
	Rotor_Gear_Pitch_Radius=Rotor_Gear_Pitch_Radius
);

if ($preview) {
	//===========================================
	//   Assembled engine

	color("SteelBlue")
		translate([ECC*sin(ALPHA), -ECC*cos(ALPHA), 0])
			rotate([0, 0, ALPHA/3])
				rotor();

	translate([0, 0, 0.01-1])
		housing();

	color("LightGray")
		rotate(180, [0,1,0])
			mount();

	translate([0, 0, Thickness/2])
		mirror([0, 0, 1])
			central_gear();

	color("FireBrick")
		rotate([0, 0, ALPHA])
			translate([0, 0, Thickness+Clearance])
				rotate(180, [0,1,0])
					eccentric();
}
else {
	//===========================================
	// This section places individual parts so they can be
	// easily exported as STL.

	translate([-Rotor_Radius-Mounting_Tab_Size, Rotor_Radius+Mounting_Tab_Size, 0])
		rotate([0, 0, -75])
			rotor();

	translate([Rotor_Radius*1.2+Mounting_Tab_Size, Rotor_Radius*1.5+Mounting_Tab_Size, 0]) {
		difference() {
			housing();
			translate([0, 0, Thickness])
				scale([1, 1, 2])
					mount();
		}
		central_gear();
	}

	rotate([0, 0, 45])
		mount();

	translate([-Rotor_Radius*1.2, -Rotor_Radius, 0])
		eccentric();
}

module central_gear() {
	translate([0, 0, Thickness/4])
		gear(
			Tooth_Size,
			Stator_Gear_Teeth,
			Thickness/2,
			Hole_Diameter,
			clearance=Clearance,
			backlash=Clearance
		);
	difference() {
		translate([-Hole_Radius-1, -Hole_Radius-1, Thickness/2])
			cube([Hole_Diameter+2, Hole_Diameter+2, 1]);
		translate([0, 0, -0.5])
			cylinder(d=Hole_Diameter, h=Thickness/2+2);
	}
}

module mount() {
	s = Motor_Size / 2 * SQRT2;

	difference() {
		union() {
			for (i = [0:3])
				rotate([0, 0, 45-i*90]) {
					translate([0, s, 0])
						difference() { // mount tab
							cylinder(r=Mount_Tab_R, h=2); // outside diameter
							translate([0, 0, 1])
								cylinder(r=Mount_Tab_R-0.6, h=2); // inside diameter
						}
					translate([-Mount_Tab_R, 0, 0])
						cube([Mount_Tab_R*2, s, 1]);
				}
			translate([0, 0, 0.5])
				cube([Hole_Diameter+6, Hole_Diameter+6, 1], center=true);
		}
		translate([0, 0, 0.5])
			cube([Hole_Diameter+2, Hole_Diameter+2, 2], center=true);
	}
}

module rotor() {
	difference() {
		rotate([0, 0, 30])
			bulgieTriangle();
		translate([0, 0, -1])
			cylinder(r=Eccentric_Radius, h=Thickness+2);
	}
	translate([0, 0, Thickness/4])
		gear(
			Tooth_Size,
			Rotor_Gear_Teeth,
			Thickness/2,
			Rotor_Gear_Outer_Radius*2+0,
			clearance=Clearance,
			backlash=Clearance
		);
}

module housing() {
	R = Rotor_Radius * 2/3;
	r = Rotor_Radius * 1/3;
	linear_extrude(height=Thickness+1, convexity=4)
		difference() {
			offset(delta=Clearance+2)
				epitrochoid(R, r, ECC);
			offset(delta=Clearance)
				epitrochoid(R, r, ECC);
		}
}

module eccentric() {
	cylinder(r=Hole_Radius-Clearance, h=Thickness+2+Clearance*2);
	translate([0, -ECC, Thickness/4]) {
		r = Eccentric_Radius - Clearance;
		difference() {
			cylinder(r=r, h=Thickness/2, center=true);
			cylinder(r=r-1, h=Thickness/2+2, center=true);
		}
		cube([1, r*2-1, Thickness/2], center=true);
	}
}

module reuleaux(r) {
	r2 = r / 2;
	n = fragments(r=r, a=60);
	a = 60 / n;
	y = r*SIN60 - r2;
	polygon([
		for (i = [n*0:n*1-1]) [r*cos(a*i)-r2, r*sin(a*i)-y],
		for (i = [n*2:n*3-1]) [r*cos(a*i)+r2, r*sin(a*i)-y],
		for (i = [n*4:n*5-1]) [r*cos(a*i),    r*sin(a*i)+r2],
	]);
}

module bulgieTriangle() {
	r = sqrt(Rotor_Radius*Rotor_Radius + Rotor_Radius*Flatness + Flatness*Flatness);
	intersection() {
		translate([Flatness, 0, 0])
			cylinder(r=r, h=Thickness);
		translate([-Flatness/2, Flatness*SIN60, 0])
			cylinder(r=r, h=Thickness);
		translate([-Flatness/2, -Flatness*SIN60, 0])
			cylinder(r=r, h=Thickness);
	}
}

module epitrochoid(R, r, d) {
	n = fragments(R);
	rs = R + r;
	dth = 360/n;
	rth = rs / r * dth;
	polygon([for (i = [0:n-1]) [
		rs*cos(dth*i) - d*cos(rth*i),
		rs*sin(dth*i) - d*sin(rth*i)
	],], convexity=4);
}

function fragments(r,a=360)=$fn>0?($fn>3?$fn:3):ceil(max(min(a/$fa,r*2*PI/$fs),5));
