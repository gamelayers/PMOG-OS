// Large Stars

/*# AVOID COLLISIONS #*/
;if(window.jQuery) (function($){
/*# AVOID COLLISIONS #*/
	
	// default settings
	$.ratingLg = {
		cancelLg: 'Cancel Rating',   // advisory title for the 'cancel' link
		cancelLgValue: '',           // value to submit when user click the 'cancel' link
		split: 0,                  // split the star into how many parts?
		
		// Width of star image in case the plugin can't work it out. This can happen if
		// the jQuery.dimensions plugin is not available OR the image is hidden at installation
		starWidth: 28,
		
		//NB.: These don't need to be defined (can be undefined/null) so let's save some code!
		//half:     false,         // just a shortcut to settings.split = 2
		//required: false,         // disables the 'cancel' button so user can only select one of the specified values
		//readOnly: false,         // disable rating plugin interaction/ values cannot be changed
		//focus:    function(){},  // executed when stars are focused
		//blur:     function(){},  // executed when stars are focused
		//callback: function(){},  // executed when a star is clicked
		
		// required properties:
		groups: {},// allows multiple star ratings on one page
		event: {// plugin event handlers
			fill: function(n, el, settings, state){ // fill to the current mouse position.
				//if(window.console) console.log(['fill', $(el), $(el).prevAll('.star_group_'+n), arguments]);
				this.drain(n);
				$(el).prevAll('.starLg_group_'+n).andSelf().addClass('starLg_'+(state || 'hover'));
				// focus handler, as requested by focusdigital.co.uk
				var lnk = $(el).children('a'); val = lnk.text();
				if(settings.focus) settings.focus.apply($.ratingLg.groups[n].valueElem[0], [val, lnk[0]]);
			},
			drain: function(n, el, settings) { // drain all the stars.
				//if(window.console) console.log(['drain', $(el), $(el).prevAll('.star_group_'+n), arguments]);
				$.ratingLg.groups[n].valueElem.siblings('.starLg_group_'+n).removeClass('starLg_on').removeClass('starLg_hover');
			},
			reset: function(n, el, settings){ // Reset the stars to the default index.
				if(!$($.ratingLg.groups[n].current).is('.cancelLg'))
					$($.ratingLg.groups[n].current).prevAll('.starLg_group_'+n).andSelf().addClass('starLg_on');
				// blur handler, as requested by focusdigital.co.uk
				var lnk = $(el).children('a'); val = lnk.text();
				if(settings.blur) settings.blur.apply($.ratingLg.groups[n].valueElem[0], [val, lnk[0]]);
			},
			click: function(n, el, settings){ // Selected a star or cancelled
				$.ratingLg.groups[n].current = el;
				var lnk = $(el).children('a'); val = lnk.text();
				// Set value
				$.ratingLg.groups[n].valueElem.val(val);
				// Update display
				$.ratingLg.event.drain(n, el, settings);
				$.ratingLg.event.reset(n, el, settings);
				// click callback, as requested here: http://plugins.jquery.com/node/1655
				if(settings.callback) settings.callback.apply($.ratingLg.groups[n].valueElem[0], [val, lnk[0]]);
			}      
		}// plugin events
	};
	
	$.fn.ratingLg = function(instanceSettings){
		if(this.length==0) return this; // quick fail
		
		instanceSettings = $.extend(
			{}/* new object */,
			$.ratingLg/* global settings */,
			instanceSettings || {} /* just-in-time settings */
		);
		
		// loop through each matched element
		this.each(function(i){
			
			var settings = $.extend(
				{}/* new object */,
				instanceSettings || {} /* current call settings */,
				($.metadata? $(this).metadata(): ($.meta?$(this).data():null)) || {} /* metadata settings */
			);
			
			////if(window.console) console.log([this.name, settings.half, settings.split], '#');
			
			// Generate internal control ID
			// - ignore square brackets in element names
			var n = (this.name || 'unnamed-rating').replace(/\[|\]+/g, "_");
   
			// Grouping
			if(!$.ratingLg.groups[n]) $.ratingLg.groups[n] = {count: 0};
			i = $.ratingLg.groups[n].count; $.ratingLg.groups[n].count++;
			
			// Accept readOnly setting from 'disabled' property
			$.ratingLg.groups[n].readOnly = $.ratingLg.groups[n].readOnly || settings.readOnly || $(this).attr('disabled');
			
			// Things to do with the first element...
			if(i == 0){
				// Create value element (disabled if readOnly)
				$.ratingLg.groups[n].valueElem = $('<input type="hidden" name="' + n + '" value=""' + (settings.readOnly ? ' disabled="disabled"' : '') + '/>');
				// Insert value element into form
				$(this).before($.ratingLg.groups[n].valueElem);
				
				if($.ratingLg.groups[n].readOnly || settings.required){
					// DO NOT display 'cancel' button
				}
				else{
					// Display 'cancel' button
					$(this).before(
						$('<div class="cancel"><a title="' + settings.cancel + '">' + settings.cancelValue + '</a></div>')
						.mouseover(function(){ $.ratingLg.event.drain(n, this, settings); $(this).addClass('starLg_on'); })
						.mouseout(function(){ $.ratingLg.event.reset(n, this, settings); $(this).removeClass('starLg_on'); })
						.click(function(){ $.ratingLg.event.click(n, this, settings); })
					);
				}
			}; // if (i == 0) (first element)
			
			// insert rating option right after preview element
			eStarLg = $('<div class="starLg"><a title="' + (this.title || this.value) + '">' + this.value + '</a></div>');
			$(this).after(eStarLg);
			
			// Half-stars?
			if(settings.half) settings.split = 2;
			
			// Prepare division settings
			if(typeof settings.split=='number' && settings.split>0){
				var stw = ($.fn.width ? $(eStarLg).width() : 0) || settings.starLgWidth;
				var spi = (i % settings.split), spw = Math.floor(stw/settings.split);
				$(eStarLg)
				// restrict star's width and hide overflow (already in CSS)
				.width(spw)
				// move the star left by using a negative margin
				// this is work-around to IE's stupid box model (position:relative doesn't work)
				.find('a').css({ 'margin-left':'-'+ (spi*spw) +'px' })
			};
			
			// Remember group name so controls within the same container don't get mixed up
			$(eStarLg).addClass('starLg_group_'+n);
			
			// readOnly?
			if($.ratingLg.groups[n].readOnly)//{ //save a byte!
				// Mark star as readOnly so user can customize display
				$(eStarLg).addClass('starLg_readonly');
			//}  //save a byte!
			else//{ //save a byte!
				$(eStarLg)
				// Enable hover css effects
				.addClass('starLg_live')
				// Attach mouse events
				.mouseover(function(){ $.ratingLg.event.drain(n, this, settings); $.ratingLg.event.fill(n, this, settings, 'hover'); })
				.mouseout(function(){ $.ratingLg.event.drain(n, this, settings); $.ratingLg.event.reset(n, this, settings); })
				.click(function(){ $.ratingLg.event.click(n, this, settings); });
			//}; //save a byte!
			
			////if(window.console) console.log(['###', n, this.checked, $.ratingLg.groups[n].initial]);
			if(this.checked) $.ratingLg.groups[n].current = eStarLg;
			
			//remove this checkbox
			$(this).remove();
			
			// reset display if last element
			if(i + 1 == this.length) $.ratingLg.event.reset(n, this, settings);
		
		}); // each element
			
		// initialize groups...
		for(n in $.ratingLg.groups)//{ not needed, save a byte!
			(function(c, v, n){ if(!c) return;
				$.ratingLg.event.fill(n, c, instanceSettings || {}, 'on');
				$(v).val($(c).children('a').text());
			})
			($.ratingLg.groups[n].current, $.ratingLg.groups[n].valueElem, n);
		//}; not needed, save a byte!
		
		return this; // don't break the chain...
	};
	
	
	
	/*
		### Default implementation ###
		The plugin will attach itself to file inputs
		with the class 'multi' when the page loads
	*/
	$(function(){ $('input[type=radio].starLg').ratingLg(); });
	
	
	
/*# AVOID COLLISIONS #*/
})(jQuery);
/*# AVOID COLLISIONS #*/

