rotor_radius = 40;
// Pitch radius
rotor_gear_radius = 17;
// Must be even number!!
stator_gear_teeth = 14;
// for large flatness $fn will need to be higher
flatness = 50;
thickness = 8;

//===========================================
// General stuff
//$fn = $preview ? 60 : 80; // facet number
$fa = $preview ? 8 : 1;  // facet angle
$fs = $preview ? 5 : 2;  // facet size
alpha = 360 * $t; // for animation

//===========================================
// Gears
// These parameters are common to both gears

hole_diameter = 0+0;
twist = 0+0;
teeth_to_hide = 0+0;
pressure_angle = 28;
clearance = 0.3;
backlash = 0.2;

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

	translate([ecc*sin(alpha), -ecc*cos(alpha), thickness/2]) {
		rotate([0, 0, alpha/3]) {
			wankelRotor (mm_per_tooth,
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

	color("red")
	rotate([0, 0, alpha])
		eccentric(thickness, ecc, rotor_gear_outer_radius, housing_hole_rad);
}
else {
	//===========================================
	// This section places individual parts so they can be 
	// easily exported as STL.

	translate([-rotor_radius,rotor_radius,thickness/2])
		wankelRotor (mm_per_tooth,
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


module wankelRotor (mm_per_tooth,
	n_rotor_gear, thickness,
	hole_diameter, twist, teeth_to_hide, pressure_angle,
	rotor_radius, flatness, 
	rotor_gear_outer_radius
) {
	union() {
		translate([0,0,-thickness/4])
			internal_gear ( mm_per_tooth, n_rotor_gear, thickness/2,  
				hole_diameter, twist, teeth_to_hide,   
				pressure_angle, 0, 0);
		difference() {
			bulgieTriangle(rotor_radius, flatness, thickness);
			// Slip ring cutout
			cylinder(r = 0.99 * rotor_gear_outer_radius, h = 1.1*thickness, center = true);
		}
	}
}


module housing(mm_per_tooth, stator_gear_teeth, thickness, 
	hole_diameter, twist, teeth_to_hide,   
	pressure_angle, clearance, backlash,
	rotor_radius, ecc, housing_hole_rad
) {
	housing_clearance = 1.01;
	n = $preview ? 40 : 100;
	//echo(str("housing length is ",2.6*rotor_radius," mm"));
	difference() {
		union() {
			difference() {
				translate([0, 0, thickness/4])
					cube([2*rotor_radius, 2.6*rotor_radius, 3/2*thickness], center=true);
				epitrochoidLinear(housing_clearance*2/3*rotor_radius,
						 housing_clearance*1/3*rotor_radius, 
						ecc, n, n, 3/2*thickness, 0);
			}
			gear(mm_per_tooth, stator_gear_teeth, thickness,  
				hole_diameter, twist, teeth_to_hide,   
				pressure_angle, clearance, backlash);
		}
		cylinder(r = housing_hole_rad, h = 4*thickness, center = true);
	}
}


module slipRing(thickness, ecc, rotor_gear_outer_radius, housing_hole_rad) {
	r = 0.98 * 0.99 * rotor_gear_outer_radius;
	difference() {
		cylinder(r = r, h = thickness/2, center = true);
		cylinder(r = r-2, h = thickness/2+2, center = true);
	}
	rotate(90, [0,0,1])
	cube([r*2-3, 2, thickness/2], center=true);
}


module eccentric(thickness, ecc, rotor_gear_outer_radius, housing_hole_rad) {
	union() {
		translate([0,0,-thickness/2])
			cylinder(r = 0.98 * housing_hole_rad, h = 2*thickness, center = true);
		translate([0, -ecc, 3/4*thickness+0.01]) {
			slipRing(thickness, ecc, rotor_gear_outer_radius, housing_hole_rad);
		}
	}
}


module bulgieTriangle(bt_R, bt_flatness, bt_thickness) {
	r_bigCirc = sqrt(bt_R*bt_R + bt_R*bt_flatness + bt_flatness*bt_flatness);
	rotate([0, 0, 30])
		intersection() {
			translate([bt_flatness, 0, 0])
				cylinder(r = r_bigCirc, h = bt_thickness, center = true);
			translate([- 0.5 * bt_flatness, sin(60) * bt_flatness, 0])
				cylinder(r = r_bigCirc, h = bt_thickness, center = true);
			translate([- 0.5 * bt_flatness, -sin(60) * bt_flatness, 0])
				cylinder(r = r_bigCirc, h = bt_thickness, center = true);
		}
}


module epitrochoidLinear(R, r, d, n, p, thickness, twist) {
	// Epitrochoid Wedge, Linear Extrude
	echo(p);
	dth = 360/n;
	linear_extrude(height = thickness, convexity = 10, twist = twist) {
		union() {
			for ( i = [0:p-1] ) {
				polygon(
					points = [
						[0, 0], 
						[(R+r)*cos(dth*i) - d*cos((R+r)/r*dth*i), (R+r)*sin(dth*i) - d*sin((R+r)/r*dth*i)], 
						[(R+r)*cos(dth*(i+1)) - d*cos((R+r)/r*dth*(i+1)), (R+r)*sin(dth*(i+1)) - d*sin((R+r)/r*dth*(i+1))]
					],
					paths = [[0, 1, 2]],
					convexity = 10
				); 
			}
		}
	}
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
		for (i = [0:number_of_teeth-teeth_to_hide-1] )
			rotate([0,0,i*360/number_of_teeth])
				linear_extrude(height = thickness, center = true, convexity = 10, twist = twist)
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
		cylinder(h=2*thickness+1, r=hole_diameter/2, center=true);
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
function iang(r1,r2) = sqrt((r2/r1)*(r2/r1) - 1)/3.1415926*180 - acos(r1/r2);

//radius a fraction f up the curved side of the tooth 
function q7(f,r,b,r2,t,s) = q6(b,s,t,(1-f)*max(b,r)+f*r2);

//point at radius d on the involute curve
function q6(b,s,t,d) = polar(d,s*(iang(b,d)+t));
