// This set of functions pop up a message on how to give Firefox permission to download xpi files from our website
// Uses InstallTrigger per Mozilla to give xpi location and icon
// For details, see http://developer.mozilla.org/en/docs/Installing_Extensions_and_Themes_From_Web_Pages

    // save the window height when the page loads
    var g_onloadHeight = window.innerHeight;

    // function to check if the yellow Allowed-Sites bar displayed.
    function InstallBarCheck(id) {
        if ( document.getElementById("pmog@gamelayers.com") ) {
            document.getElementById("pmog@gamelayers.com").style.marginTop='0px';
        }
        document.getElementById(id).style.display='none';
        if (g_onloadHeight > window.innerHeight) {
            document.getElementById(id).style.display='block';
            if ( document.getElementById("pmog@gamelayers.com") ) {
                document.getElementById("pmog@gamelayers.com").style.marginTop='80px';
            }
        }
        setTimeout(function() {InstallBarCheck(id);}, 500);
    }
 
    // pmog for Firefox      
    function installpmogFF(event) {
        try {
          var params = {
            "PMOG_for_Firefox": {
              URL: "http://pmog.com/firefox/pmog.xpi",
              IconURL: "http://pmog.com/images/ext/p-32.png"
            }
          };
          InstallTrigger.install(params);
          InstallBarCheck('pmog_install_how_to');
        } catch (e) {
          return true;
        }
        return false;
    }