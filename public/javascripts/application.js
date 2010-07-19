// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

// This is to ajaxify paginating links.
//  Event.addBehavior.reassignAfterAjax = true;
//  Event.addBehavior({
//    'div.pagination a' : Remote.Link
//  })

jQuery(document).ajaxSend(function(event, request, settings) {
    if (typeof(window.AUTH_TOKEN) == "undefined") return;
    settings.data = settings.data || "";
    settings.data += (settings.data ? "&" : "") + "authenticity_token=" + encodeURIComponent(window.AUTH_TOKEN);
});

jQuery(function() {
    // DO contact mouseovers, etc.
    jQuery('.avatarPop').prev().append('<a href="javascript:;" class="opener"></a>');
    jQuery('.avatarOver').append('<a href="javascript:;" class="closer"></a>');
    jQuery('.avatarPop').hide();

    jQuery('a.opener').click(function() {
        jQuery(this).parent().next('.avatarPop').show();
        return false;
    });

    jQuery('a.closer').click(function() {
        jQuery(this).parents('.avatarPop').hide();
        return false;
    });

    jQuery('.avatarPop').hover(function() {
        jQuery(this).fadeIn(100);
    }, function() {
        jQuery(this).fadeOut(500);
    });

});


var updateInterval = 5000; // update every 2 seconds
var timestamp = new Date().toString();
var timer;

function go() {
  timer = setInterval('updateSpy()', updateInterval);
}

function updateSpy() {
  jQuery.ajax({
    url: '/events_spy?timestamp=' + timestamp,
    type: 'GET',
    dataType: 'script',
    success: function() {
      timestamp = new Date().toString();
    }
  });
}