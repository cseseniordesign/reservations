
CREATE TABLE IF NOT EXISTS `maker_requests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uuid` char(36) NOT NULL,
  `category_id` int(11) NOT NULL,
  `status_id` int(11) NOT NULL,
  `requestor_name` varchar(255) NOT NULL,
  `requestor_email` varchar(255) NOT NULL,
  `requestor_phone` varchar(50) DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `created` datetime NOT NULL,
  `updated` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY (`uuid`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;

-- Add admin_notes column to events table
ALTER TABLE `events` ADD COLUMN `admin_notes` text NULL AFTER `description`;

-- Add Events Read-only access
INSERT INTO `permissions` VALUES (9, 'Events Admin Read-only');

-- Add category id to resources
ALTER TABLE `resources` ADD COLUMN `category_id` int(11) NULL AFTER `name`;

--Update-user-table-default-password
ALTER TABLE `reservation`.`users` 
CHANGE COLUMN `password_hash` `password_hash` VARCHAR(255) NULL DEFAULT '$2a$12$RGRjbe3xauqpFLf3eMskVOITvZgrHsDdZ/0zr03zxFNQM3k3HFOHS';

--Add expiration_reminders-table
CREATE TABLE IF NOT EXISTS `expiration_reminders` (
  `ID` INT(11) NOT NULL AUTO_INCREMENT,
  `first_reminder` INT(11) NOT NULL,
  `second_reminder` INT(11) NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

--Add default value for expiration reminders
INSERT INTO `reservation`.`expiration_reminders` (`ID`, `first_reminder`, `second_reminder`) VALUES ('1', '3', '0');

--Add is_trainer to users table
ALTER TABLE `reservation`.`users`
ADD COLUMN `is_trainer` INT NULL DEFAULT 0 AFTER `is_super_admin`;

--Add trainer_id to events
ALTER TABLE `reservation`.`events`
ADD COLUMN `trainer_id` INT NULL AFTER `unl_events_id`;
ALTER TABLE `reservation`.`events`
ADD CONSTRAINT `FK_trainer_id`
  FOREIGN KEY (`trainer_id`)
  REFERENCES `reservation`.`users` (`id`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

--Add preset events table
CREATE TABLE IF NOT EXISTS `reservation`.`preset_events` (
  `id` INT(11) NOT NULL,
  `event_name` VARCHAR(255) NULL,
  `description` VARCHAR(255) NULL,
  `event_type_id` INT(11) NULL,
  `max_signups` INT(11) NULL,
  `duration` INT(11) NULL,
  PRIMARY KEY (`id`),
  INDEX `event_type_id_idx` (`event_type_id` ASC) VISIBLE,
  CONSTRAINT `event_type_id`
    FOREIGN KEY (`event_type_id`)
    REFERENCES `reservation`.`event_types` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE);

--Update preset_events table
ALTER TABLE `reservation`.`preset_events` 
CHANGE COLUMN `id` `id` INT(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `reservation`.`preset_events` 
CHANGE COLUMN `description` `description` VARCHAR(4000) NULL DEFAULT NULL;

--Add preset_events_has_resources table
CREATE TABLE IF NOT EXISTS `reservation`.`preset_events_has_resources` (
  `preset_events_id` INT(11) NOT NULL,
  `resources_id` INT(11) NOT NULL,
  PRIMARY KEY (`preset_events_id`, `resources_id`),
  INDEX `fk_preset_events_has_resources_resources1_idx` (`resources_id` ASC) VISIBLE,
  INDEX `fk_preset_events_has_resources_preset_events1_idx` (`preset_events_id` ASC) VISIBLE,
  CONSTRAINT `fk_preset_events_has_resources_preset_events1`
    FOREIGN KEY (`preset_events_id`)
    REFERENCES `reservation`.`preset_events` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_preset_events_has_resources_resources1`
    FOREIGN KEY (`resources_id`)
    REFERENCES `reservation`.`resources` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);

--Insert preset events into preset_events table
INSERT INTO `reservation`.`preset_events` (`event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES (
'Basic Lathe Training: Metal',
"Cost:  $100
Please be aware that this class is based on the basic safety and operations of a manual lathe.  It is not project specific class. 
WEEK 1
Intro to Clausing Lathe controls.
Discussion of General Lathe safety.
1) No long sleave shirts
2) No jewelry, watches, rings
3) Long hair tied up or put under a ball cap.
Intro to basic digital readout functions.
Tightening material into lathe jaws.
How to setting height for cutting tool.
Machine face cuts into steel
Machine turning cuts into steel

WEEK 2
Review of Lathe machine controls.
Review of Basic Lathe Safety
Taking multiple facing and turning cuts into steel bar working to dimensions.
Setting up and using parting tool.

WEEK 3
Review of Lathe machine controls
Review of Basic Lathe Safety
Drill and tap a series of holes to size in Steel bar.
1) Center drill hole 
2) Drill series of Holes to specific size
3) Tap series of Hole to specific size",
'2',
'2',
'120');
INSERT INTO `reservation`.`preset_events` (`event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES (
'Adobe Illustrator One-on-One Open Hours',
"Cost:  Free with active membership
Learn Illustrator from the experts in a one on one setting.  Whether you know nothing, know something or think you know it all you will gain valuable skills when navigating Illustrator for your laser, vinyl cutter or silk screen projects.  ",
'5',
'10',
'60');
INSERT INTO `reservation`.`preset_events` (`event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES (
'Pottery Wheel Basics Workshop',
"Cost:  Free with active membership
In this class you'll learn the basics of operating the pottery wheels including centering, wedging and throwing techniques as well as how to use the various tools available in the studio.  Member ______ will also teach you about the different types of clay you should use for your project, the firing processes for our kilns and some glazing basics. ",
'5',
'5',
'90');
INSERT INTO `reservation`.`preset_events` (`event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES (
'Hand Building with Clay ',
"Cost:  Free with active membership 
Spend 2 hours on 2 separate days with resident sculptor ______ hand sculpting a project of your choice. 
In class 1 you will sculpt something small, with _____ guidance, to build your basic skills. 
In class 2 you will sculpt a project of your choosing, so show up with your ideas and _______ will Swayze you through your project from start to finish.
Please sign up for both sessions of this workshop.",
'5',
'5',
'120');
INSERT INTO `reservation`.`preset_events` (`event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES (
'Advanced Silk Screen Workshop: Using multiple colors',
'Cost:  Free with active membership 
Before taking this workshop you must have completed silkscreen training or already be familiar with the silkscreening process.
In this 1.5 hour workshop we will cover more advanced silk screen printing methods. 
You will learn how to use multiple screens to create a final image with multiple colors.  You will also learn how to create graphic files with multiple colors using Adobe Illustrator.  Please be sure to bring a blank t-shirt to the workshop.',
'5',
'4',
'90');
INSERT INTO `reservation`.`preset_events` (`event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES 
('Woodworking Session:  Wood Lathes', 
"Cost: $50.00
Payment must be made in person or on the phone prior to being allowed to sign up for this training.  If you're interested in signing up please call or stop in today
In this two part Workshop you will learn the anatomy of a wood lathe, carbide vs high speed steel tools, the basics of spindle turning, and the basics of bowl turning.  After this workshop you will be able to make reservations and use the small wood lathes. 
Session 1 
We will begin in the classroom and go over the anatomy of the wood lathe and how they work.  Following that you'll learn the basics of spindle turning by turning a pen on the lathe.
Session 2
In session 2 we will go over bowl turning basics from rough logs to finished bowl and you will turn a shallow dish.",
'5', 
'10', 
'90');
INSERT INTO `reservation`.`preset_events` ( `event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES ('New Member Orientation', 'Cost: None
Attending a New Member Orientation is required in order to gain access to Innovation Studio.
At the 1-hour orientation session you will take a tour of the Studio and become familiar with our policies, procedures, and practices.  Please review the website before orientation and come with any questions you may have.  
You will receive an email with a parking map attached confirming your signup.  MAKE SURE YOU PARK WHERE DIRECTED.
Our main entrance, 2021 Transformation Drive, Suite 1500, Entrance B, is located on the North-west end of the Innovation Commons building on 19th St. just off Transformation Drive.   
Studio membership payment is accepted in the forms of credit cards and NCards. Checks or cash are not accepted.  Please be prepared with your preferred form of payment on the day of your New Member Orientation.  
Please note that this Orientation is for people who are ready to become a member.  If you are interested in learning more about the studio before joining, feel free to email us at innovationstudio@unl.edu, take a virtual tour at https://nebraskainnovationcampus.com/,  or call us at 402.472.5114.
', '1', '30', '60');
INSERT INTO `reservation`.`preset_events` ( `event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES ('Tour of Nebraska Innovation Studio', 'Cost: None
Have you heard about Innovation Studio but do not know enough about it to sign up as a member?  Not sure you are ready to commit?  Wondering what the studio offers to its members?  Spend 30 minutes with our staff to learn all you need to know.  We will walk through the entire studio, show you our equipment, tell you how to use the studio, and answer any other questions you may have to help you with your decision.  The studio is located at 2021 Transformation Drive, Suite 1500 Entrance B.  (On the NW corner of Innovation Campus at 19th & Transformation Drive-you can see Devaney Center from our door.)
', '8', '20', '30');
INSERT INTO `reservation`.`preset_events` ( `event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES ('Epilog Laser Cutter Training', 'Cost:  Free with active membership
This 1-hour training is required before gaining access to the Epilog Fusion 40, 32, 32 Pro & 24 laser cutters. Learn the basics of generating a file to send to the lasers, how to operate the lasers, the differences between the three, and the basic use of the rotary tool.
', '2', '6', '60'); 
INSERT INTO `reservation`.`preset_events` ( `event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES ('3D Printer Training #1 – Ultimaker', 'Cost:  Free with active membership
This 1 hour training is required before gaining access to the Ultimaker 2+ and 3-Extended printers.  We will review the printer software and demonstrate how to upload your files and operate the equipment.  This training does not cover design software. You must complete this training before taking the Formlab & Markforged training.
', '2', '6', '60');
INSERT INTO `reservation`.`preset_events` ( `event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES ('3D Printer Training #2 – Formlab & Markforged', 'Cost:  Free with active membership
In order to use the Formlab & Markforged 3d printers you must have already completed the Ultimaker 3d training.  This 1 hour training is required before gaining access to the Formlab & Markforged 3d printers.  We will review the printer software, review the different types of material for each printer, and demonstrate how to upload yourc files and operate the equipment.  This training does not cover design software.
', '2', '6', '60');
INSERT INTO `reservation`.`preset_events` ( `event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES ('Band Saw, Scroll Saw, & Drill Press Training: Wood', 'Cost:  Free with active membership
This 1 hour training is required before gaining access to the band saws, scroll saw & drill press for wood.  In this training you will make several cuts using both saws and learn the basics of drilling with our press, the different drill bits we have available and what materials they are used with to ensure you are operating these machines safely and effectively. 
', '2', '6', '60');
INSERT INTO `reservation`.`preset_events` ( `event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES ('Jointer & Planer Training: Wood', 'Cost:  Free with active membership
This 1 hour training is required before gaining access to the wood jointer & planer. In this training you will gain an understanding of the cut settings and operational limitations of each piece of equipment and ensure you are operating these machines safely and effectively.
', '2',  '6', '60');
INSERT INTO `reservation`.`preset_events` ( `event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES ('Drum, Belt, Disc, & Spindle Sander Training: Wood', 'Cost:  Free with active membership
This 1 hour training is required before gaining access to the drum, belt, disc & spindle sanders for wood.  In this training you will gain an understanding of how to select the correct sander for the job and ensure you are operating these machines safely and effectively. 
', '2', '6', '60');
INSERT INTO `reservation`.`preset_events` ( `event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES ('Table Router, Hoffman Router, Mortising Machine Training: Wood', 'Cost:  Free with active membership
This one hour training is required before gaining access to the table router, Hoffman router, and Mortising machine for wood.  In jthis training you will review the hand routers and cut with table and Hoffman routers in order to gain an understanding of how to select the correct router for your project and ensure you are operating these machines safely and effectively.   You will also learn how to safely operate the mortising machine and cut a mortise.
', '2', '6', '60');
INSERT INTO `reservation`.`preset_events` ( `event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES ('Table, Miter, & Panel Saw Training: Wood', 'Cost:  Free with active membership
This 1 hour training is required before gaining access to the table saw, miter saw and panel saws. In this training you will become familiar with the operation of the panel saw and make several cuts on both the miter and table saws. You will leave with a basic understanding of their operation and ensure you are operating these machines safely and effectively.
', '2', '4', '60');
INSERT INTO `reservation`.`preset_events` ( `event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES ('Carvey Desktop CNC Training', 'Cost:  Free with active membership
This 1 hour training is required before gaining access to the Carvey Desktop CNC router and must be completed before taking the Shopbot CNC router training.  In this training you will learn how to use the Easel software to create and set up your file, set up the machine and cut your project using materials ranging from plywood, hardwood, plastics, and many others.  This machine has a 12” x 8” x 2.75” work area and is designed for smaller, more detailed projects than the Shopbot CNC.
', '2',  '6', '60');
INSERT INTO `reservation`.`preset_events` ( `event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES ('Shopbot CNC Router Training', 'Cost:  Free with active membership
In order to sign up for this 1.5 hour required Shopbot CNC training you must first complete the Carvey Desktop CNC training.  In this training you will learn to code tool paths for the router in VCarve Pro as well as how to operate the CNC router.  Allowable materials are wood, foam & certain composites.
', '2', '6', '90');
INSERT INTO `reservation`.`preset_events` ( `event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES ('Woodshop One on One', 'Cost:  Free with active membership
This 30 minute training allows you to consult with an instructor on your specific project.  During this training you may choose up to three pieces of woodshop equipment to train on.  In this training you will learn the basics and practice using this equipment to ensure you are operating these machines safely and effectively.
', '2', '1', '30');
INSERT INTO `reservation`.`preset_events` ( `event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES ('Vinyl Cutter & Heat Press Training', 'Cost:  Free with active membership 
This 1 hour training is required before gaining access to the vinyl cutter and vinyl heat press.  Learn the basics of generating a file in Illustrator and Graphtec Studio as well as how to load your vinyl, cut your file and create your finished vinyl transfer.   You will also learn how to set up the vinyl cutter for the heat press and operate the heat press correctly and effectively.
', '2', '6', '60');
INSERT INTO `reservation`.`preset_events` ( `event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES ('Screen Print Training', 'Cost:  Free with active membership 
This 1 hour required training will guide you through the creation and application of a silkscreen.  You will learn how to print your image, apply emulsion, set up your screen, apply ink, clean and remove your image from the screen, and operate our 4 station press.  
', '2', '6', '60');
INSERT INTO `reservation`.`preset_events` ( `event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES ('Embroidery Machine Training', 'Cost:  Free with active membership
This 1 hour training is required before gaining access to our Baby Lock 6 needle embroidery machine.  You will learn how to thread the machine, how to operate the machine, and how to use stock images and create text that you can then embroider on a shirt, towel or hat.
You may sign up for the advanced software training after completing this training.  This software will allow you to design & create your own images to embroider on your object.
', '2', '6', '60');
INSERT INTO `reservation`.`preset_events` ( `event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES ('Long Arm Quilter Training', 'Cost:  Free with active membership
This 3 hour training will give you the basic operating skills for our long arm quilting machine. 
In this course you will learn to:
Load a quilt on the long arm quilting machine
Thread the machine, change thread and wind bobbins
Align a pantograph for quilting and quilt using a pantograph design
Noodle around doing a bit of free motion quilting from the front of machine
What to bring:
Excitement for learning the basics of long arming. Supplies will be provided - we will use small panel quilt tops which will be donated to Quilts for Kids, a charity which provides area hospitals with quilts for children who are receiving treatment.
Please arrive 10 minutes early as we will start promptly. 
', '2', '4', '180');
INSERT INTO `reservation`.`preset_events` ( `event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES ('Metal Shop Equipment Orientation', 'Cost:  Free with active membership
Our brand new metal shop is full of useful equipment and is set up to meet as many of your metal working needs as possible.  This 1.5 hour shop orientation will give you an overview of what the equipment can do, the types of material that can be used, some of the new personal protection & safety requirements, and allow you to ask questions about how the metal shop and the equipment use will function.  This is not equipment specific training, this is an opportunity to get the wheels turning for your metal projects.  You will be able to sign up for trainings separately.
', '2', '10', '90');
INSERT INTO `reservation`.`preset_events` ( `event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES ('Metalshop One on One', 'Cost:  Free with active membership
This 30-60 minute training allows you to receive an overview of all equipment or to train on specific equipment. You may choose from media blaster, grinders & sanders, horizontal, vertical, and cold saws, shear, brake, ironworker, virtual reality welder, welders, tube bender, media blaster, english wheel, and slip roller. Plasma Cutter & Fiber Laser, mills & lathes, are separate trainings.
', '2', '1', '60');
INSERT INTO `reservation`.`preset_events` ( `event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES ('CNC Plasma Cutter Training: Metal', 'Cost:  Free with active membership
In this training you will learn to code tool paths for the plasma cutter in the SheetCam software, operate the CNC plasma cutter using the Mach3 software, select your cutting consumables, as well as how to operate the CNC router safely and efficiently.  Allowable materials are steel and stainless steel. Aluminum is not permitted.  Check out the SOP on our website.
', '2', '4', '60');
INSERT INTO `reservation`.`preset_events` ( `event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES ('CNC Fiber Laser Training: Metal', 'Cost:  Free with active membership
In this 1 hour training you will learn to code tool paths for the fiber laser using the FabCreator software, gain a brief introduction to VCarve and the tube fab plugin for Solidworks, as well as operate the CNC fiber laser safely and efficiently to cut, engrave, and raster metals.  Allowable materials are cold rolled steel, stainless steel, aluminum, titanium, copper and brass.  Maximum material dimensions are 50” x 25” sheet or 2” square, round, or rectangular tube.
', '2', '4', '60');
INSERT INTO `reservation`.`preset_events` ( `event_name`, `description`, `event_type_id`, `max_signups`, `duration`) VALUES ('Basic Milling Machine Training: Metal', 'Cost:  $100
Payment must be made in person, at the studio, prior to being allowed to sign up for this training.  Limit 2 members per training session.  This is a 5 week, 2 hours per session, one session per week training.
You must provide proof of vaccination prior to training.
This training is required before gaining supervised access to our Bridgeport knee mills.  This class will introduce you to basic milling machine operations.  You will then be able to work with one of our machinists on specific projects in a supervised environment.  
The weekly sessions will cover the following:
WEEK 1
1)	Intro to Bridgeport series 1 milling machine, controls.
2)	How to install and remove milling cutters.
3)	How to check square and adjust vice and tram on milling machine.
4)	Intro to basic digital readout functions.
5)	Set up a repeatable stop.
6)	Taking off vice and using hold down clamps for larger parts.
Week 2
1)	Review of milling machine controls.
2)	Review of checking square of vice.
3)	Review of installing and removing milling cutters.
4)	Discussion and example of climb and conventional milling.
5)	Setting up stock to mill in machine.
a)	Deburr the stock material.  
b)	Use layout line to setup part in milling machine vice.
c)	Pick correct parallels to machine the part.
d)	Install correct milling cutter and set correct speed for size of milling cutter. 
e)	Take face and edge cuts on Plastic to the correct dimensions.
6)	Repeat step 4 for Aluminum.
7)	Repeat step 4 for Cold Rolled Steel.
Week 3  
1)	Review of milling machine controls.
2)	Review of checking square of vice.
3)	How to tram in head to table on milling machine.
4)	How to use an edge finder to find 0,0 point on part,  set digital readout to 0,0
5)	Drilling holes in Plastic, Aluminum, Steel
a)	How to determine drill speed for various types of materials.
b)	Use of a center drill to start holes.
c)	Discussion that drill bits have webs and to drill larger holes need to step up the drill sizes.
6)	From drawing locate and drill holes of various sizes in Plastic.
7)	Repeat step 6 for Aluminum.
8)	Repeat step 6 for Cold Rolled Steel.

WEEK 4
1)	Review of milling machine controls.
2)	Review of checking square of vice.
3)	Basic theory on machining a slot.
4)	Using center cutting milling cutters to plunge into material.
5)	Using drills to remove most of material in slot.
6)	Machine slot into plastic.
a)	From drawing determine size of cutter to use.
b)	Set a second datum on digital readout to aid in machining pocket accurately.
c)	Machine slot into Plastic.
7)	Repeat step 6 with Aluminum.
8)	Repeat step 6 with Cold Rolled Steel.
9)	Machine pocket into Plastic.
a)	Determine type and size of milling cutter to use.
b)	Rough cut pocket to size.
c)	Finish cut pocket to size.
10)	Repeat Step 9 for Aluminum.
11)	Repeat Step 9 for Cold Rolled Steel.
WEEK 5
1)	Review of milling machine controls.
2)	Review of checking square of vice.
3)	Set 0,0 point on part using edge finder and digital readout.
4)	Drilling and Tapping Basics in Plastic.
a)	Determine the correct size of drill for tapping threads.
b)	Position table to drill hole in correct location.
c)	Center drill and the drill hole. 
d)	Tap hole into part.
e)	Repeat for 3 sizes of tapped hole, 10-32, ¼-20, 3/8-16. 
5)	Repeat step 4 for Aluminum.
6)	Repeat step 4 for Cold Rolled Steel.
7)	Drill and tapping a bolt circle using a second datum in Plastic.
8)	Repeat Step 7 for Aluminum.
9)	Repeat Step 7 for Cold Rolled Steel.
', '2', '2', '120');

--Insert preset events tools into preset_events_has_resources
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('1', '772');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('1', '773');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('2', '791');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('2', '792');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('2', '793');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('2', '794');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('2', '795');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('2', '796');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('2', '797');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('9', '12');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('9', '732');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('9', '782');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('9', '818');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('10', '14');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('10', '49');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('10', '733');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('10', '739');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('10', '740');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('10', '742');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('10', '811');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('10', '812');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('10', '813');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('10', '821');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('10', '822');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('10', '824');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('10', '825');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('17', '734');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('18', '8');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('20', '23');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('21', '51');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('22', '743');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('23', '47');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('26', '757');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('27', '815');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('28', '770');
INSERT INTO `reservation`.`preset_events_has_resources` (`preset_events_id`, `resources_id`) VALUES ('28', '771');

-- Fix one of the durations of the preset_events
UPDATE `preset_events` SET `duration`=60 where `id`=10; 

-- Add confirmed_trainer to events
ALTER TABLE `reservation`.`events` 
ADD COLUMN `trainer_confirmed` TINYINT NULL DEFAULT 0 AFTER `trainer_id`;

-- Add preset emails table
CREATE TABLE IF NOT EXISTS `reservation`.`preset_emails` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NULL,
  `subject` VARCHAR(255) NULL,
  `body` VARCHAR(10000) NULL,
  PRIMARY KEY (`id`));

-- Add default preset emails
INSERT INTO `reservation`.`preset_emails`
(`name`,
`subject`,
`body`)
VALUES
('New Members',
'New Members', ''
);
INSERT INTO `reservation`.`preset_emails`
(`name`,
`subject`,
`body`)
VALUES
('Snow Day',
'Snow Day', 'NIS is closed due to inclement weather.  All active memberships have been extended by one day. 

 

Your NIS Staff'
);
INSERT INTO `reservation`.`preset_emails`
(`name`,
`subject`,
`body`)
VALUES
('Wood Lathe',
'Wood Lathe', 'Monday X/X and X/X - 6pm-9pm - Woodworking Workshop: Wood Lathes - 6 Slots Open - $50.00 
Pre-requisite trainings:  None 
In this two part Workshop you will learn the anatomy of a wood lathe, carbide vs high speed steel tools, the basics of spindle turning, and the basics of bowl turning.  After this workshop you will be able to make reservations and use the small wood lathes.   All materials are included.  Call or stop in to reserve your spot, payment due at registration. 

 

Your NIS Staff '
);
INSERT INTO `reservation`.`preset_emails`
(`name`,
`subject`,
`body`)
VALUES
('New Members',
'New Members', ''
);
 INSERT INTO `reservation`.`preset_emails`
(`name`,
`subject`,
`body`)
VALUES
('Purge',
'Material Storage Purge', 'NIS will be purging all material storage on Wednesday X/X/X at 12pm.  Active members are allowed to store one project at a time.  Any unlabeled materials or materials belonging to expired members will be discarded on Wednesday X/X/X.  Any usable discarded material will be available for free at 5pm on Wednesday X/X/X. 

 

Your NIS Staff'
);
INSERT INTO `reservation`.`preset_emails`
(`name`,
`subject`,
`body`)
VALUES
('Openings in Metal Lathe/Mill/Tormach CNC Mill',
'Openings in Metal Lathe/Mill/Tormach CNC Mill', ''
);
INSERT INTO `reservation`.`preset_emails`
(`name`,
`subject`,
`body`)
VALUES
('TIG Welding Workshop ',
'TIG Welding Workshop ', ''
);
INSERT INTO `reservation`.`preset_emails`
(`name`,
`subject`,
`body`)
VALUES
('Parking Information',
'Parking Information', 'There are volleyball and football games Thursday and Saturday this week. The parking lot in which our members park will be paid event parking both days. In order to avoid paying for parking you must stop in the studio and grab a red parking permission tag from the sign in table, then proceed to the parking lot, show the tag to the attendant, and park without paying fees. 
Thanks for your understanding! 

Your NIS staff '
); 
INSERT INTO `reservation`.`preset_emails`
(`name`,
`subject`,
`body`)
VALUES
('Cleanup Reminder',
'Cleanup Reminder', 'Dear NIS Members, We are experiencing a large increase in the number of people using the Studio.  As we see this continue to increase we wanted to remind you of two very important expectations for using The Studio.

Make a reservation when you are planning to use tables or equipment.  Reservations help us track usage and more importantly make sure equipment and tables are not double booked. 

Clean up after yourself.  We need everyone to plan for an appropriate amount of time to clean up after themselves to leave things cleaner than you found them.  This applies to specific areas as well as project storage. 

Thank you, 
Your NIS Staff'
);

-- Create alerts table
CREATE TABLE IF NOT EXISTS `alerts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `category_id` int(11) NOT NULL,
  `description` text DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1

-- Create alert_signups table
CREATE TABLE IF NOT EXISTS `alert_signups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `alert_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1

-- Create vehicles table
CREATE TABLE `reservation`.`vehicles` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `license_plate` VARCHAR(255) NULL,
  `state` VARCHAR(255) NULL,
  `make` VARCHAR(255) NULL,
  `model` VARCHAR(255) NULL,
  `user_id` INT(11) NULL,
  PRIMARY KEY (`id`),
  INDEX `user_id_idx` (`user_id` ASC) VISIBLE,
  CONSTRAINT `user_id`
    FOREIGN KEY (`user_id`)
    REFERENCES `reservation`.`users` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE);

    -- Create event_authorizations table
    CREATE TABLE IF NOT EXISTS `event_authorizations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `event_id` int(11) NOT NULL,
  `resource_id` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1

-- Create preset_events_has_resource_reservations table
    CREATE TABLE IF NOT EXISTS `preset_events_has_resource_reservations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `preset_events_id` int(11) NOT NULL,
  `resource_id` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1

-- Add authorized_event column to resource_authorizations
ALTER TABLE `reservation`.`resource_authorizations` 
ADD COLUMN `authorized_event` INT(11) NULL DEFAULT NULL AFTER `authorized_date`;

-- Create Scheduling Event Type
INSERT INTO `reservation`.`event_types` (`id`, `description`, `service_space_id`) VALUES ('10', 'Scheduling', '1');

-- Alter event table to include "private" column
ALTER TABLE `reservation`.`events` 
ADD COLUMN `is_private` TINYINT(1) NULL DEFAULT 0 AFTER `trainer_confirmed`;

-- Alter event table to include "event_code" column
ALTER TABLE `reservation`.`events` 
ADD COLUMN `event_code` VARCHAR(255) NULL AFTER `public`;

-- Add email status columns to users table
ALTER TABLE `reservation`.`users`
ADD COLUMN `functional_email_status` TINYINT(1) DEFAULT 1 after `expiration_date`,
ADD COLUMN `news_email_status` TINYINT(1) DEFAULT 1 after `functional_email_status`,
ADD COLUMN `reminder_email_status` TINYINT(1) DEFAULT 1 after `news_email_status`,
ADD COLUMN `promotional_email_status` TINYINT(1) DEFAULT 1 after `reminder_email_status`;

-- Add email types table
CREATE TABLE IF NOT EXISTS `reservation`.`email_types` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NULL,
  PRIMARY KEY (`id`));

-- Insert default email types
CREATE TABLE `reservation`.`email_types` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NULL,
  PRIMARY KEY (`id`));

-- Add scheduling event type
INSERT INTO `reservation`.`event_types` (`id`, `description`, `service_space_id`) VALUES ('10', 'Scheduling', '1');