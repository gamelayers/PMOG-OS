/**
 * @author  remy sharp / http://remysharp.com
 * @url     http://remysharp.com/2007/05/18/add-twitter-to-your-blog-step-by-step/
 * @usage   getTwitters(cssIdOfContainer, { id: myTwitterId, count: n, prefix: string, clearContents: bool });
 * @params
 *   cssIdOfContainer: e.g. twitters
 *   options: 
 *       {
 *           id: {String} username,
 *           count: {Int} 1-20, defaults to 1
 *           prefix: {String} '%name% said', defaults to blank
 *           clearContents: {Boolean} true, removes contents of element specified in cssIdOfContainer, defaults to false
 *           ignoreReplies: {Boolean}, skips over tweets starting with '@', defaults to false
 *           withFriends: {Boolean} includes friend's status 
 *           template: {String} HTML template to use for LI element (see URL above for examples), defaults to predefined template
 *       }
 *
 * @license Creative Commons License - ShareAlike http://creativecommons.org/licenses/by-sa/3.0/
 * @version 1.8 - fixed ignoreReplies count=1 returning nothing
 * @updated 2008-04-11
 */

// to protect variables from resetting if included more than once
if (typeof renderTwitters != 'function') (function () {
    /** Private variables */
    var browser = (function() {
    	var b = navigator.userAgent.toLowerCase();

    	// Figure out what browser is being used
    	return {
    		safari: /webkit/.test(b),
    		opera: /opera/.test(b),
    		msie: /msie/.test(b) && !(/opera/).test(b),
    		mozilla: /mozilla/.test(b) && !(/(compatible|webkit)/).test(b)
    	};
    })();

    var guid = 0;
    
    /** Global functions */
    
    // to create a public function within our private scope, we attach the 
    // the function to the window object
    window.renderTwitters = function (obj, options) {
        // private shortcuts
        function node(e) {
            return document.createElement(e);
        }
        
        function text(t) {
            return document.createTextNode(t);
        }

        var target = document.getElementById(options.twitterTarget);
        var data = null;
        var ul = node('ul'), li, statusSpan, timeSpan, i, max = obj.length > options.count ? options.count : obj.length;
        
        for (i = 0; i < max && obj[i]; i++) {
            data = getTwitterData(obj[i]);
            
            // if we requested frieds, mangle the object in to match timelines - future feature - not sure if it's worth while
            /*if (obj[i].screen_name) {
                obj[i].user = obj[i];
                obj[i].created_at = obj[i].status.created_at;
                obj[i].text = obj[i].status.text;
            }*/           
                        
            if (options.ignoreReplies && obj[i].text.substr(0, 1) == '@') {
                max++;
                continue; // skip
            }
            
            li = node('li');
            
            if (options.template) {
                li.innerHTML = options.template.replace(/%([a-z_\-\.]*)%/ig, function (m, l) {
                    var r = data[l] + "" || "";
                    if (l == 'text' && options.enableLinks) r = r.linkify();
                    return r;
                });
            } else {
                statusSpan = node('span');
                statusSpan.className = 'twitterStatus';
                timeSpan = node('span');
                timeSpan.className = 'twitterTime';
                statusSpan.innerHTML = obj[i].text; // forces the entities to be converted correctly

                if (options.enableLinks == true) {
                    statusSpan.innerHTML = statusSpan.innerHTML.linkify();
                }

                timeSpan.innerHTML = relative_time(obj[i].created_at);

                if (options.prefix) {
                    var s = node('span');
                    s.className = 'twitterPrefix';
                    s.innerHTML = options.prefix.replace(/%(.*?)%/g, function (m, l) {
                        return obj[i].user[l];
                    });
                    li.appendChild(s);
                    li.appendChild(text(' ')); // spacer :-(
                }

                li.appendChild(statusSpan);
                li.appendChild(text(' '));
                li.appendChild(timeSpan);
            }
            
            ul.appendChild(li);
        }

        if (options.clearContents) {
            while (target.firstChild) {
                target.removeChild(target.firstChild);
            }
        }

        target.appendChild(ul);
    };
    
    window.getTwitters = function (target, id, count, options) {
        guid++;
        
        if (typeof id == 'object') {
            options = id;
            id = options.id;
            count = options.count;
        } 

        if (!count) count = 1;
        
        if (options) {
            options.count = count;
            if (options.ignoreReplies && count == 1) {
                count = 2;
            }
        } else {
            options = {};
        }

        // need to make these global since we can't pass in to the twitter callback
        options['twitterTarget'] = target;

        // this looks scary, but it actually allows us to have more than one twitter
        // status on the page, which in the case of my example blog - I do!
        window['twitterCallback' + guid] = function (obj) {
            renderTwitters(obj, options);
        };

        // check out the mad currying!
        ready((function(options, guid) {
            return function () {
                // if the element isn't on the DOM, don't bother
                if (!document.getElementById(options.twitterTarget)) {
                    return;
                }
                
                var url = 'http://www.twitter.com/statuses/' + (options.withFriends ? 'friends_timeline' : 'user_timeline') + '/' + id + '.json?callback=twitterCallback' + guid + '&count=' + count;

                var script = document.createElement('script');
                script.setAttribute('src', url);
                document.getElementsByTagName('head')[0].appendChild(script);
            };
        })(options, guid));
    };

    /** Private functions */
    
    function getTwitterData(orig) {
        var data = orig, i;
        for (i in orig.user) {
            data['user_' + i] = orig.user[i];
        }
        
        data.time = relative_time(orig.created_at);
        
        return data;
    }

    // ready and browser adapted from John Resig's jQuery library (http://jquery.com)
    function ready(callback) {
        if ( browser.mozilla || browser.opera ) {
            document.addEventListener( "DOMContentLoaded", callback, false );
        } else if ( browser.msie ) {
            // If IE is used, use the excellent hack by Matthias Miller
            // http://www.outofhanwell.com/blog/index.php?title=the_window_onload_problem_revisited

            // Only works if you document.write() it
            document.write("<scr" + "ipt id=__ie_init defer=true src=//:><\/script>");

            // Use the defer script hack
            var script = document.getElementById("__ie_init");

            // script does not exist if jQuery is loaded dynamically
            if (script) {
                script.onreadystatechange = function() {
                    if ( this.readyState != "complete" ) return;
                    this.parentNode.removeChild( this );
                    callback.call();
                };
            }

            // Clear from memory
            script = null;

            // If Safari  is used
        } else if ( browser.safari ) {
            // Continually check to see if the document.readyState is valid
            var safariTimer = setInterval(function () {
                // loaded and complete are both valid states
                if ( document.readyState == "loaded" || 
                document.readyState == "complete" ) {

                    // If either one are found, remove the timer
                    clearInterval( safariTimer );
                    safariTimer = null;
                    // and execute any waiting functions
                    callback.call();
                }
            }, 10);
        }
    }
    
    function relative_time(time_value) {
        var values = time_value.split(" ");
        time_value = values[1] + " " + values[2] + ", " + values[5] + " " + values[3];
        var parsed_date = Date.parse(time_value);
        var relative_to = (arguments.length > 1) ? arguments[1] : new Date();
        var delta = parseInt((relative_to.getTime() - parsed_date) / 1000);
        delta = delta + (relative_to.getTimezoneOffset() * 60);

        var r = '';
        if (delta < 60) {
            r = 'less than a minute ago';
        } else if(delta < 120) {
            r = 'about a minute ago';
        } else if(delta < (45*60)) {
            r = (parseInt(delta / 60)).toString() + ' minutes ago';
        } else if(delta < (2*90*60)) { // 2* because sometimes read 1 hours ago
            r = 'about an hour ago';
        } else if(delta < (24*60*60)) {
            r = 'about ' + (parseInt(delta / 3600)).toString() + ' hours ago';
        } else if(delta < (48*60*60)) {
            r = '1 day ago';
        } else {
            r = (parseInt(delta / 86400)).toString() + ' days ago';
        }

        return r;
    }

    String.prototype.linkify = function() {
        return this.replace(/[A-Za-z]+:\/\/[A-Za-z0-9-_]+\.[A-Za-z0-9-_:%&\?\/.=]+/g, function(m) {
            return m.link(m);
        }).replace(/@[\S]+/g, function(m) {
            return '<a href="http://twitter.com/' + m.substr(1) + '">' + m + '</a>';
        });
    };
})();