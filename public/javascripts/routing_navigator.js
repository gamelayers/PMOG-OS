var RoutingNavigatorPanel = {
  show: function(link) {
    var panel = $(link.getAttribute('id').match(/([\w-]+)-tab$/)[1]);
    this.hide(panel);
    
    Effect.toggle(panel, 'appear', {duration:0.25, afterFinish: function() { new Effect.ScrollTo(panel, {duration:0.25}); }});
    return false;
  },
  
  hide: function(link) {
    $$('#routing-navigator .routing-navigator-tab').each(function(panel) {
      if(panel != link) { // dont close the given link
        if(panel.getElementsByTagName('p').length == 0) { // generate a close link for this panel
          var closeLink  = document.createElement('a');
          closeLink.href = '#'
          closeLink.appendChild(document.createTextNode('close'));
          closeLink.onclick = RoutingNavigatorPanel.hide;
          var p = document.createElement('p');
          p.appendChild(closeLink);
          panel.appendChild(p);
        }
        panel.hide();
      }
    });
    return false;
  }
}