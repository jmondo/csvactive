# csvactive
## Pronunciation
csv-active or c-s-vactive
(because that's super important)

## What
It's a ruby script to help you process data. It:
- takes a csv,
- does some semi-intellegent data parsing/converting,
- creates a database,
- migrates it,
- creates you a model,
- dumps you in a console to play with your data the rails way

## Why
I've noticed that people use excel for lots of things. And guru excel users think [v-lookup](http://office.microsoft.com/en-us/excel-help/vlookup-HP005209335.aspx) is crack. When in reality one of the simplest database functions (a join) would be a million times more powerful in accomplishing their task. And then instead of pushing the limits, they are starting at the ground floor.

And here's the thing about that:
- sequel syntax is ugly and intimidating
- ActiveRecord makes it easier to learn and understand
- it has a great [guide](http://guides.rubyonrails.org/active_record_querying.html)
- you can call .to_sql!
- if you learn how to deal with a single data table with AR, then you learn joins, then you learn rails.

Boom. V-lookup => csvactive => rails. \#gatewaydrug

Sounds important _now_ right?

## How to use
You need
- ruby 1.9.3 (there's something wrong when run in 1.8, but it's not going to keep me from shipping this thing!)
- rubygems
- internets?

From a console in the csvactive directory

    bundle install
    ruby csvactive.rb <put csv file path here>
    # like this: ruby csvactive.rb ~/Desktop/somefile.csv

things happen, then you pop into a console with a model called Thing.
let's say your CSV had roster data. try these things:

    Thing.first.first_name            # find the first person's first name
    Thing.where(first_name: 'John')   # find all the cool people
    Thing.order(:first_name)          # order them by first name
    Thing.pluck(:first_name)          # grab an array of all the first names
    Thing.pluck(:first_name).to_sql   # learn!

you can also have fun with floats and dates. if your data has numbers or dates in it, the script will figure it out and convert them before saving to database

    Thing.where("things.start_date >= #{3.days.ago}")  # find the employees that started in the last 3 days
    Thing.where("things.magic_stars >= 4")             # find star performers

once you've mastered that, add [squeel](https://github.com/ernie/squeel) to the mix

    Thing.where{start_date >= 3.days.ago}
    Thing.where{(name =~ 'Ernie%') & (salary < 50000) | (name =~ 'Joe%') & (salary > 100000)}

can excel do that?

## How it works
- using a home grown regular expression for float matching (covering parenthesis negatives, - signs, and percents)
- using [chronic](https://github.com/mojombo/chronic) for datetime parsing
- using Ruby CSV library to parse CSV with live conversion
- using [pry](https://github.com/pry/pry) to throw you into a live console deep into your app
- using sqlite to avoid tons of dependencies (feel free to change it up and use your own db - uses similar database.yml to rails)
- using ActiveRecord for power

## Help me
- make it faster
- make it work on 1.8 (something is wrong with the regexp to start)
- make it easier for noobs to get it up and running - after all, that's the primary target (i'm second.) - installing ruby and calling via command line is clunky.
- write tests, if that's the kind of thing you like to do

so yeah, contribute - open an issue or pull request or what not. i'm always listening. :)
and give feedback! i'd love to hear if this helps anyone other than myself and my coauthor @polyfish42
tweet me [@jmondo](http://twitter.com/jmondo)
