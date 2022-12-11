
Installation
============

Using local resources
---------------------
0. Run `xcode-select --install`. Congratulations, you have saved yourself 5000 insanity points.
1. Get the right ruby on your machine. UNL Resource Scheduler currently runs on Ruby 2.6.5. Get RVM on your machine with `\curl -sSL https://get.rvm.io | bash`.
2. Now using RVM, install the ruby with `rvm install 2.6.5`.
3. You probably do not have the `bundler` gem. Check with `bundle`. If not, install it with `gem install bundler`.
4. In the project root, install the gems using `bundle install`.
5. Create a mysql database you'd like to use, you can typically use one on your computer. `brew install mysql` if necessary. 
6. `config/config.json` is a committed file, and a template for the configuration. Create a copy in the same directoy named `server.json` and edit it to match your database.
7. Your database is currently blank. Import the production database or copy https://git.unl.edu/iim/unl-resource-scheduler/tree/master/db/migrate into this project and run the migrations from the root of the project using `rake migrate` to bring in all the tables and columns.
8. Install the WDN Framework into the `public/wdn` directory...see [WDN Documentation](http://wdn.unl.edu/documentation).
9. Start the server by going to the root directory and doing `bundle exec shotgun -o 0.0.0.0 -p 9393`. This launches the server on localhost port 9393, listening everywhere (you can use your iimlemburg.unl.edu or whichever), and the server will automatically update to new code. If you add gems to the bundle, you will need to re-execute this command.
10. Navigate to `localhost:9393/` or similar and begin!
11. In another terminal, type `bundle exec guard` in the project root to execute LESS compilation.

Quick Tutorial
==============
1. Service spaces refer to different silos of the University that will utilize resources. E.g. the math department, the Honors program, or University Communication.
2. Super Admins of a space can do anything, including giving others access and privileges to the space.
3. Resources are created, and then may be reserved by anyone who has the User Access privilege in the space. 
4. Events *may* include a resource reservation but do not have to.
5. Admins with the right privilege can set the *hours* of the space, which indicate when reservations can be made.
6. The agenda is a quick overview of the day for Admins to look at. 

Deploying Updates on Production
===============================
```
$ sudo -u innovationstudio -s -H
$ systemctl --user restart unicorn
```