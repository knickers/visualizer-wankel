// Distance between the stepper motor screws
Motor_Size = 31; // [20:0.1:50]
// Diameter inside the motor screw holes
Mounting_Tab_Size = 6.15; // [4.5:0.01:7.5]
// Motor mount tab radius
Mount_Tab_R = Mounting_Tab_Size / 2;

rotor_radius = Motor_Size * 0.6;
// Pitch radius
rotor_gear_radius = rotor_radius * 0.425;
// Must be even number!!
stator_gear_teeth = 14;
// for large flatness $fn will need to be higher
flatness = 50;
thickness = 8;

//===========================================
// General stuff
//$fn = $preview ? 60 : 80; // facet number
$fa = $preview ? 3 : 1;  // facet angle
$fs = $preview ? 1.25 : 0.75;  // facet size
alpha = 360 * $t; // for animation
SQRT2 = sqrt(2);  // Square root of 2

//===========================================
// Gears
// These parameters are common to both gears

hole_diameter = 0+0;
twist = 0+0;
teeth_to_hide = 0+0;
pressure_angle = 28;
clearance = 0.25;
backlash = 0.125;

//===========================================
//   Given the above parameters, we can determine the rest of the rotor and housing geometry
//
//   Eccentricity is the offset distance of the crank (the crank is also known as the "eccentric").  
//   Eccentricity is also the difference in pitch radii of the two gears.

ecc = rotor_gear_radius / 3;
//echo(str("Eccentricity is ",ecc," mm"));
n_rotor_gear = 3/2 * stator_gear_teeth; 
mm_per_tooth = 2 * PI * rotor_gear_radius / n_rotor_gear;
//echo(str("mm_per_tooth is ",mm_per_tooth," mm"));
rotor_gear_outer_radius =  mm_per_tooth * n_rotor_gear / PI / 2 + mm_per_tooth / PI + mm_per_tooth/2;
housing_hole_rad = 0.6 * mm_per_tooth * stator_gear_teeth / PI / 2;

if ($preview) {
	//   Assembled engine

	translate([ecc*sin(alpha), -ecc*cos(alpha), 0]) {
		rotate([0, 0, alpha/3]) {
			rotor(mm_per_tooth,
				n_rotor_gear, thickness,
				hole_diameter, twist, teeth_to_hide, pressure_angle,
				rotor_radius, flatness, 
				rotor_gear_outer_radius
			);
		}
	}

	housing(mm_per_tooth, stator_gear_teeth, thickness, 
		hole_diameter, twist, teeth_to_hide,   
		pressure_angle, clearance, backlash,
		rotor_radius, ecc, housing_hole_rad
	);

	*color("red")
	rotate([0, 0, alpha])
		translate([0, 0, clearance])
			eccentric(thickness, ecc, rotor_gear_outer_radius, housing_hole_rad);
}
else {
	//===========================================
	// This section places individual parts so they can be 
	// easily exported as STL.

	translate([-rotor_radius,rotor_radius,thickness/2])
		rotor(mm_per_tooth,
			n_rotor_gear, thickness,
			hole_diameter, twist, teeth_to_hide, pressure_angle,
			rotor_radius, flatness, 
			rotor_gear_outer_radius
		);

	translate([rotor_radius+5,0,thickness/2])
		housing(mm_per_tooth, stator_gear_teeth, thickness, 
			hole_diameter, twist, teeth_to_hide,   
			pressure_angle, clearance, backlash,
			rotor_radius, ecc, housing_hole_rad
		);

	translate([-rotor_radius,-rotor_radius/1.5,thickness])
		rotate(180, [0,1,0])
			eccentric(thickness, ecc, rotor_gear_outer_radius, housing_hole_rad);
}

module mount_tab() {
	difference() {
		cylinder(r = Mount_Tab_R, h = 1); // outside diameter
		translate([0, 0, -1])
			cylinder(r = Mount_Tab_R-0.6, h = 3); // inside diameter
	}
}

module mounts() {
	s = Motor_Size / 2 * SQRT2;

	translate([0, 0, -1])
	for (i = [0:3])
		rotate([0, 0, 45-i*90])
			translate([0, s, 0])
				mount_tab();
}

module rotor(mm_per_tooth,
	n_rotor_gear, thickness,
	hole_diameter, twist, teeth_to_hide, pressure_angle,
	rotor_radius, flatness, 
	rotor_gear_outer_radius
) {
	union() {
		internal_gear(mm_per_tooth, n_rotor_gear, thickness/2,
			hole_diameter, twist, teeth_to_hide,
			pressure_angle, 0, 0);
		difference() {
			rotate(30, [0,0,1])
				linear_extrude(thickness)
					reuleaux(rotor_radius, flatness);
			// Slip ring cutout
			translate([0, 0, thickness/2-0.01])
				cylinder(r=rotor_gear_outer_radius, h=thickness/2+1);
			translate([0, 0, -1])
				cylinder(r=rotor_gear_outer_radius*0.9, h=thickness/2+2);
		}
	}
}

module housing(mm_per_tooth, stator_gear_teeth, thickness, 
	hole_diameter, twist, teeth_to_hide,   
	pressure_angle, clearance, backlash,
	rotor_radius, ecc, housing_hole_rad
) {
	housing_clearance = 1.01;
	n = $preview ? 40 : 120;
	R = housing_clearance*2/3*rotor_radius;
	r = housing_clearance*1/3*rotor_radius;
	difference() {
		union() {
			linear_extrude(height=3/2*thickness, convexity=10, twist=twist) {
				difference() {
					offset(delta=2)
						epitrochoid(R, r, ecc);
					epitrochoid(R, r, ecc);
				}
			}
			gear(mm_per_tooth, stator_gear_teeth, thickness,  
				hole_diameter, twist, teeth_to_hide,   
				pressure_angle, clearance, backlash);
			mounts();
		}
		cylinder(r = housing_hole_rad, h = 4*thickness, center = true);
	}
}

module slipRing(thickness, ecc, rotor_gear_outer_radius, housing_hole_rad) {
	r = rotor_gear_outer_radius - clearance;
	difference() {
		cylinder(r=r, h=thickness/2, center=true);
		cylinder(r=r-1, h=thickness/2+2, center=true);
	}
	translate([0, 0.5-r/2, 0])
		cube([1, r-1, thickness/2], center=true);
}

module eccentric(thickness, ecc, rotor_gear_outer_radius, housing_hole_rad) {
	union() {
		translate([0,0,-thickness/2-clearance*2])
			cylinder(r = 0.98 * housing_hole_rad, h = 1.5*thickness + clearance*2);
		translate([0, -ecc, 3/4*thickness+0.01]) {
			slipRing(thickness, ecc, rotor_gear_outer_radius, housing_hole_rad);
		}
	}
}

module reuleaux(bt_R, bt_flatness) {
	r_bigCirc = sqrt(bt_R*bt_R + bt_R*bt_flatness + bt_flatness*bt_flatness);
	n = fragments(r=r_bigCirc, a=120);
	a = 120 / n;
	s60 = sin(60);
	o = 15;
	echo(n=n, a=a, s60=s60);
	polygon([
		/**/
		for (i = [o:n-o-1]) [
			r_bigCirc*cos(a*i) - bt_flatness/2,
			r_bigCirc*sin(a*i) - bt_flatness*s60
		],
		/**/
		/**/
		for (i = [n+o:n*2-o-1]) [
			r_bigCirc*cos(a*i) + bt_flatness,
			r_bigCirc*sin(a*i)
		],
		/**/
		for (i = [n*2+o:n*3-o-1]) [
			r_bigCirc*cos(a*i) - bt_flatness/2,
			r_bigCirc*sin(a*i) + bt_flatness*s60
		],
		/**/
	]);
}

module bulgieTriangle(bt_R, bt_flatness, bt_thickness) {
	r_bigCirc = sqrt(bt_R*bt_R + bt_R*bt_flatness + bt_flatness*bt_flatness);
	rotate([0, 0, 30])
		intersection() {
			translate([bt_flatness, 0, 0])
				cylinder(r=r_bigCirc, h=bt_thickness, center=true);
			translate([- 0.5 * bt_flatness, sin(60) * bt_flatness, 0])
				cylinder(r=r_bigCirc, h=bt_thickness, center=true);
			translate([- 0.5 * bt_flatness, -sin(60) * bt_flatness, 0])
				cylinder(r=r_bigCirc, h=bt_thickness, center=true);
		}
}

module epitrochoid(R, r, d) {
	n = fragments(R);
	rs = R + r;
	dth = 360/n;
	rth = rs / r * dth;
	polygon([
		for (i = [0:n-1])
			[rs*cos(dth*i) - d*cos(rth*i), rs*sin(dth*i) - d*sin(rth*i)],
	], convexity=5);
}

module internal_gear (
	// This is just a quick edit of Leemon's gear() module to make an internal gear
	mm_per_tooth    = 3,    //this is the "circular pitch", the circumference of the pitch circle divided by the number of teeth
	number_of_teeth = 11,   //total number of teeth around the entire perimeter
	thickness       = 6,    //thickness of gear in mm
	hole_diameter   = 3,    //diameter of the hole in the center, in mm
	twist           = 0,    //teeth rotate this many degrees from bottom of gear to top.  360 makes the gear a screw with each thread going around once
	teeth_to_hide   = 0,    //number of teeth to delete to make this only a fraction of a circle
	pressure_angle  = 28,   //Controls how straight or bulged the tooth sides are. In degrees.
	clearance       = 0.0,  //gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
	backlash        = 0.0   //gap between two meshing teeth, in the direction along the circumference of the pitch circle
) {
	p = mm_per_tooth * number_of_teeth / PI / 2;  //radius of pitch circle
	c = p + mm_per_tooth / PI - clearance;        //radius of outer circle
	b = p*cos(pressure_angle);                    //radius of base circle
	r = p-(c-p)-clearance;                        //radius of root circle
	t = mm_per_tooth/2-backlash/2;                //tooth thickness at pitch circle
	k = -iang(b, p) - t/2/p/PI*180;               //angle to where involute meets base circle on each side of tooth
	difference() {
		for (i = [0:number_of_teeth-teeth_to_hide-1])
			rotate([0,0,i*360/number_of_teeth])
				linear_extrude(height=thickness, convexity=10, twist=twist)
					polygon(
						points=[
							polar(c + mm_per_tooth/2, -181/number_of_teeth),
							polar(r, -181/number_of_teeth),
							polar(r, r<b ? k : -180/number_of_teeth),
							q7(0/5,r,b,c,k, 1),q7(1/5,r,b,c,k, 1),q7(2/5,r,b,c,k, 1),q7(3/5,r,b,c,k, 1),q7(4/5,r,b,c,k, 1),q7(5/5,r,b,c,k, 1),
							q7(5/5,r,b,c,k,-1),q7(4/5,r,b,c,k,-1),q7(3/5,r,b,c,k,-1),q7(2/5,r,b,c,k,-1),q7(1/5,r,b,c,k,-1),q7(0/5,r,b,c,k,-1),
							polar(r, r<b ? -k : 180/number_of_teeth),
							polar(r, 181/number_of_teeth),
							polar(c + mm_per_tooth/2, 181/number_of_teeth)
						],
						paths=[[17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0]]
					);
		cylinder(h=2*thickness+1, r=hole_diameter/2);
	}
};


//===========================================
//   This gear() module is from 
//   Leemon Baird's PublicDomainGearV1.1.scad
//   which can be found here:
//   http://www.thingiverse.com/thing:5505
//An involute spur gear, with reasonable defaults for all the parameters.
//Normally, you should just choose the first 4 parameters, and let the rest be default values.
//Meshing gears must match in mm_per_tooth, pressure_angle, and twist,
//and be separated by the sum of their pitch radii, which can be found with pitch_radius().
module gear (
	mm_per_tooth    = 3,    //this is the "circular pitch", the circumference of the pitch circle divided by the number of teeth
	number_of_teeth = 11,   //total number of teeth around the entire perimeter
	thickness       = 6,    //thickness of gear in mm
	hole_diameter   = 3,    //diameter of the hole in the center, in mm
	twist           = 0,    //teeth rotate this many degrees from bottom of gear to top.  360 makes the gear a screw with each thread going around once
	teeth_to_hide   = 0,    //number of teeth to delete to make this only a fraction of a circle
	pressure_angle  = 28,   //Controls how straight or bulged the tooth sides are. In degrees.
	clearance       = 0.0,  //gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
	backlash        = 0.0   //gap between two meshing teeth, in the direction along the circumference of the pitch circle
) {
	p = mm_per_tooth * number_of_teeth / PI / 2;  //radius of pitch circle
	c = p + mm_per_tooth / PI - clearance;        //radius of outer circle
	b = p*cos(pressure_angle);                    //radius of base circle
	r = p-(c-p)-clearance;                        //radius of root circle
	t = mm_per_tooth/2-backlash/2;                //tooth thickness at pitch circle
	k = -iang(b, p) - t/2/p/PI*180;               //angle to where involute meets base circle on each side of tooth
	difference() {
		for (i = [0:number_of_teeth-teeth_to_hide-1] )
			rotate([0,0,i*360/number_of_teeth])
				linear_extrude(height = thickness, center = true, convexity = 10, twist = twist)
					polygon(
						points=[
							[0, -hole_diameter/10],
							polar(r, -181/number_of_teeth),
							polar(r, r<b ? k : -180/number_of_teeth),
							q7(0/5,r,b,c,k, 1),q7(1/5,r,b,c,k, 1),q7(2/5,r,b,c,k, 1),q7(3/5,r,b,c,k, 1),q7(4/5,r,b,c,k, 1),q7(5/5,r,b,c,k, 1),
							q7(5/5,r,b,c,k,-1),q7(4/5,r,b,c,k,-1),q7(3/5,r,b,c,k,-1),q7(2/5,r,b,c,k,-1),q7(1/5,r,b,c,k,-1),q7(0/5,r,b,c,k,-1),
							polar(r, r<b ? -k : 180/number_of_teeth),
							polar(r, 181/number_of_teeth)
						],
						paths=[[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]]
					);
		cylinder(h=2*thickness+1, r=hole_diameter/2, center=true);
	}
};

//these 4 functions are used by gear

//convert polar to cartesian coordinates
function polar(r,theta) = r*[sin(theta), cos(theta)];

//unwind a string this many degrees to go from radius r1 to radius r2
function iang(r1,r2) = sqrt((r2/r1)*(r2/r1) - 1)/PI*180 - acos(r1/r2);

//radius a fraction f up the curved side of the tooth 
function q7(f,r,b,r2,t,s) = q6(b,s,t,(1-f)*max(b,r)+f*r2);

//point at radius d on the involute curve
function q6(b,s,t,d) = polar(d,s*(iang(b,d)+t));

function fragments(r,a=360)=$fn>0?($fn>3?$fn:3):ceil(max(min(a/$fa,r*2*PI/$fs),5));
