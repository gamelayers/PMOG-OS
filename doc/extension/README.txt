You can generate documentation for this extension by using the natural docs library

Here is a snippet i used to generate the documentation (please note the paths used 
are specific to my filesystem)

This must be executed from within the NaturalDocs folder.
./NaturalDocs -i /Users/markdaggett/Sites/clients/game_layers/svn/trunk/hud/pmog\@gamelayers.com/chrome/pmog/content/javascripts/ -o FramedHTML ~/clients/game_layers/svn/trunk/doc/extension/ -p ~/Sites/clients/game_layers/svn/trunk/doc/extension/natural_docs/


For extra credit i made a shell script that would update the documentation and commit it to the svn all from one command.
Just copy this into a shell script make it executable and then ensure your paths are correct.

cd /Applications/NaturalDocs-1.35/ && ./NaturalDocs -i /Users/markdaggett/Sites/clients/game_layers/svn/trunk/hud/pmog\@gamelayers.com/chrome/pmog/content/javascripts/ -o FramedHTML ~/clients/game_layers/svn/trunk/doc/extension/ -p ~/Sites/clients/game_layers/svn/trunk/doc/extension/natural_docs/ && cd ~/clients/game_layers/svn/trunk/doc/extension/ && svn ci -m 'updated documentation'