Copied from the Dike README, for reference - duncan 19/01/08



NAME

  dike

SYNOPSIS

  a simple memory leak detector for ruby with preconfigured rails hooks.

INSTALL

  gem install dike

URIS

  http://www.codeforpeople.com/lib/ruby/
  http://rubyforge.org/projects/codeforpeople/

DESCRIPTION

  the concept behind dike.rb is simple: class Object is extended in order that
  the location of each object's creation is tracked.  a summarizer command is
  given to walk ObjectSpace using each object's class and the location if it's
  creation to detect memory leaks.  not all leaks can be detected and some that
  are may not really be leaks, but dike provided a simple way to see the
  hotspots in your code that may potentially be leaking.

HISTORY

  0.0.4:

    - under rare circumstances dike itself interacted strangely with certain
      classes and caused them to leak, HTTPOK was one such example.  this
      release fixes that bug.  thanks to Jan Kubr for providing a great test
      case that helped me fix this.

EXAMPLES

  ### PURE RUBY

   ## just dumping sequential snapshots to stderr, looking at a specific class

    # cfp:~ > cat sample/a.rb
        require 'dike'

        class Leak < ::String
        end

        Leaks = Array.new

        Dike.filter Leak 

        loop do
          Leaks << Leak.new('leak' * 1024)
          Dike.finger
          sleep 1
        end


    # cfp:~ > ruby sample/a.rb | less
        ---
        - class: Leak
          count: 2
          trace:
          - sample/a.rb:11
          - sample/a.rb:10:in `loop'
          - sample/a.rb:10
        ---
        - class: Leak
          count: 3
          trace:
          - sample/a.rb:11
          - sample/a.rb:10:in `loop'
          - sample/a.rb:10
        ---
        - class: Leak
          count: 4
          trace:
          - sample/a.rb:11
          - sample/a.rb:10:in `loop'
          - sample/a.rb:10
        ---
        - class: Leak
          count: 5
          trace:
          - sample/a.rb:11
          - sample/a.rb:10:in `loop'
          - sample/a.rb:10
        ---
        - class: Leak
          count: 6
          trace:
          - sample/a.rb:11
          - sample/a.rb:10:in `loop'
          - sample/a.rb:10

   ## dumping sequential snapshots using Dike.logfactory and then using the 'dike'
      command line tool to do comparisons of the dumped snapshots

    # cfp:~ > cat sample/b.rb
        require 'dike'

        Leaks = Array.new

        class Leak
          def initialize
            @leak = 42.chr * (2 ** 20)
          end
        end

        Dike.logfactory './log/'

        Dike.finger

        3.times{ Leaks << Leak.new  }

        Dike.finger

        2.times{ Leaks << Leak.new  }

        Dike.finger

    # cfp:~ > ruby sample/b.rb

    # cfp:~ > ls log/
        0       1       2

    # cfp:~ > dike log/
        --- 
        - class: Leak
          count: 3
          trace: 
          - sample/b.rb:15
          - sample/b.rb:15:in `times'
          - sample/b.rb:15
        - class: Leak
          count: 2
          trace: 
          - sample/b.rb:19
          - sample/b.rb:19:in `times'
          - sample/b.rb:19

    # cfp:~ > dike log/0 log/1
        --- 
        - class: Leak
          count: 3
          trace: 
          - sample/b.rb:15
          - sample/b.rb:15:in `times'
          - sample/b.rb:15

    # cfp:~ > dike log/1 log/2
        --- 
        - class: Leak
          count: 2
          trace: 
          - sample/b.rb:19
          - sample/b.rb:19:in `times'
          - sample/b.rb:19


  ### RAILS

    # cfp:~ > cat ./config/environment.rb
      ...
      require 'dike'
      Dike.on :rails

    # cfp:~ > ./script/server

    # cfp:~ > curl --silent http://localhost:3000 >/dev/null

    # cfp:~ > cat ./log/dike/0
      ---
      - class: String
        count: 90769
        trace: []
      - class: Array
        count: 18931
        trace: []
      - class: Class
        count: 2
        trace:
        - votelink.com/public/../config/../lib/widgets.rb:222:in `class_factory'
        - votelink.com/public/../config/../lib/widgets.rb:220:in `each'
        - votelink.com/public/../config/../lib/widgets.rb:220:in `class_factory'
        - votelink.com/public/../config/../lib/widgets.rb:248:in `Widget'
        - votelink.com/public/../config/../lib/widgets/page/base.rb:1
        - votelink.com/public/../config/../lib/widgets.rb:31:in `require'
        - votelink.com/public/../config/../lib/widgets.rb:31:in `load'
        - votelink.com/public/../config/../lib/widgets.rb:16:in `for_controller'
        - votelink.com/public/../config/../lib/widgets.rb:243:in `widget'
        - votelink.com/public/../config/../app/controllers/application.rb:150
      ...

    # cfp:~ > curl --silent http://localhost:3000 >/dev/null

    # cfp:~ > cat ./log/dike/1
      ---
      - class: String
        count: 100769
        trace: []
      - class: Array
        count: 19931
        trace: []
      - class: Class
        count: 5
        trace:
        - votelink.com/public/../config/../lib/widgets.rb:222:in `class_factory'
        - votelink.com/public/../config/../lib/widgets.rb:220:in `each'
        - votelink.com/public/../config/../lib/widgets.rb:220:in `class_factory'
        - votelink.com/public/../config/../lib/widgets.rb:248:in `Widget'
        - votelink.com/public/../config/../lib/widgets/page/base.rb:1
        - votelink.com/public/../config/../lib/widgets.rb:31:in `require'
        - votelink.com/public/../config/../lib/widgets.rb:31:in `load'
        - votelink.com/public/../config/../lib/widgets.rb:16:in `for_controller'
        - votelink.com/public/../config/../lib/widgets.rb:243:in `widget'
        - votelink.com/public/../config/../app/controllers/application.rb:150
      ...

    # cfp:~ > dike ./log/dike
      ...
      - class: Class
        count: 3
        trace:
        - votelink.com/public/../config/../lib/widgets.rb:222:in `class_factory'
        - votelink.com/public/../config/../lib/widgets.rb:220:in `each'
        - votelink.com/public/../config/../lib/widgets.rb:220:in `class_factory'
        - votelink.com/public/../config/../lib/widgets.rb:248:in `Widget'
        - votelink.com/public/../config/../lib/widgets/page/base.rb:1
        - votelink.com/public/../config/../lib/widgets.rb:31:in `require'
        - votelink.com/public/../config/../lib/widgets.rb:31:in `load'
        - votelink.com/public/../config/../lib/widgets.rb:16:in `for_controller'
        - votelink.com/public/../config/../lib/widgets.rb:243:in `widget'
        - votelink.com/public/../config/../app/controllers/application.rb:150
      ...

NOTES

  * the 'Dike.finger' method dumps it's log in a format showing

    class : the class of object being leaked/allocated
    count : the number instances leaked from the trace location
    trace : the trace location of object creation

  * loading into a rails environment causes snapshots of the above format to
    be dumped into RAILS_ROOT/log/dike/ after each request.  each snapshot is
    incrementally numbered 0, 1, ...

  * the 'dike' command line tool can be used in two ways

      dike directory/with/logs/dike/

      dike old_dump new_dump

    if given a directory 'old_dump' and 'new_dump' are auto-calculated by
    scanning the directory.  in either case the tool dups a delta running old
    -->> new.  the delta shows only changes from old to new, so a line like

      - class: Proc
        count: 3 
        ...

    means that 3 Proc objects were created between the two dumps.  note that,
    when given a directory, the default old and new dumps are the oldest and
    newest dumps respectively, to get fine grained information sumarizing the
    changes between two requests give the files manually, for example
  
      dike ./log/dike/41 ./log/dike/42

  * options that affect logging

    - Dike.filter pattern

        pattern must respond to '===' and each object in ObjectSpace will be
        compared against it.  for example

          Dile.filter Array

        would cause logging to restrict itself to Array, or sublcasses of
        Array

    - Dike.log io

        set the dike logging object.  the object should respond to 'puts'.

    - Dike.logfactory directory

        cause logging to occur into a new log for each call the 'Dike.finger'.
        the logs will be auto numbered 0, 1, ...

LIMITATIONS

  not all object creation can be tracked. not all leaks are reported. some
  reported leaks are not. dike shows you where in the source objects are being
  created that cannot be reclaimed - these are not always leaks as this line

    class C; end

  shows.  the class 'C' cannot be reclaimed and yet is not a leak.

AUTHOR

  ara [dot] t [dot] howard [at] gmail [dot] com

