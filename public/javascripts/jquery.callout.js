/*
* jQuery Callout 0.1
* Copyright (c) 2008 David Von Lehman
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/// <reference path="jquery-1.2.6.js" />

(function($) {
    $.fn.callout = function(settings) {
        settings = $.extend({
            orient: "above",
            align: "left",
            text: "",
            arrowHeight: 10,
            nudgeHorizontal: 0,
            nudgeVertical: 0,
            arrowInset: 20, // The inset from the left or right edge of the callout to where the arrow begins.
            cornerRadius: 3,
            region: undefined  // The region that contains the area where the callout will appear.
        }, settings ||
        {});

        settings.target = $(this).filter(":first");

        // If there are no matched elements or a callout is already open, exit the function.
        if (settings.target.length === 0 || settings.target.data("__callout") != null) {
            return;
        }

        // Get the html content that is to be rendered in the callout.    
        var htmlContent = settings.content ? $(settings.content).html() : (settings.text || "");

        // Create a dummy element that we add to the DOM temporarily to figure out 
        // what the height and other style attributes will be.
        var dummy = $("<div/>").css({
            "position": "absolute",
            "visibility": "hidden"
        }).attr("class", settings.className)
			.html(htmlContent)
			.prependTo("body");

        if (settings.cornerRadius > 0) {
            $.each(["top", "left", "bottom", "right"], function(i, val) {
                dummy.css("padding-" + val, Math.max(dummy.pixels("padding-" + val), settings.cornerRadius));
            });
        }

        // Assuming the border width and color is consistent on all sides.
        settings = $.extend(settings,
		{
		    borderColor: $(dummy).css("border-top-color"),
		    borderWidth: $(dummy).pixels("border-top-width"),
		    backColor: $(dummy).css("background-color"),
		    zIndex: parseInt($(dummy).css("z-index"), 0),
		    paddingTop: dummy.pixels("padding-top"),
		    paddingBottom: dummy.pixels("padding-bottom"),
		    paddingLeft: dummy.pixels("padding-left"),
		    paddingRight: dummy.pixels("padding-right")
		});

        // Now that we know the correct padding and border, adjust the width of the sacraficial div
        // so we can get an accurate height.
        dummy.width(settings.width - dummy.pixels("padding-left") - dummy.pixels("padding-right") - 2 * settings.borderWidth);

        // Ensure that the callout has a zIndex greater than the base page.
        if (settings.zIndex === 0 || isNaN(settings.zIndex)) {
            settings.zIndex = 9999;
        }

        settings.mainHeight = dummy.height() + settings.paddingTop + settings.paddingBottom + 2 * settings.borderWidth;
        settings.height = settings.mainHeight + settings.arrowHeight + settings.borderWidth;

        // In IE and Chrome, the corner radius appears to cause additional padding to be rendered.
        // Reduce the padding we place on the contentBox to compensate.
        if (($.browser.msie || $.browser.chrome) && settings.cornerRadius > 0) {
            settings.paddingTop -= (settings.cornerRadius - settings.borderWidth);
            settings.paddingBottom -= (settings.cornerRadius - settings.borderWidth);
        }

        // We can destory the dummy element now.
        $(dummy).remove();

        // Dynamically create the callout container.
        var containerBox = $("<div />").attr("id", $(this).attr("id") + "_callout").css({
            "position": "absolute",
            "display": "none",
            "z-index": settings.zIndex,
            "background-color": settings.region ? $(settings.region).css("background-color") : "transparent"
        }).prependTo(settings.region ? settings.region : "body");

        // Append the main content area of the callout
        var mainBox = $("<div />").attr("id", "mainBox").css({
            "position": "absolute",
            // Set the background color to the border color so the rounded corner voids
            // don't pick up the main background color.
            "background-color": settings.borderWidth > 0 ? settings.borderColor : "transparent",
            "z-index": settings.zIndex
        }).width(settings.width).appendTo(containerBox);

        var contentBox = $("<div/>").attr("id", "contentBox").css({
            "position": "absolute",
            "background-color": settings.backColor,
            "margin-left": settings.borderWidth + "px",
            "margin-top": settings.borderWidth + "px",
            "z-index": settings.zIndex
        }).width(settings.width - 2 * settings.borderWidth).appendTo(mainBox);

        // The content inner box actually holds the markup that appears within the 
        // callout.  This allows our outer box to maintain the prescribed width 
        // without the padding throwing it off.
        var contentInnerBox = $("<div/>").attr("class", settings.className).css({
            "border": "none",  // The border and width have already been taken care of by the parent elements.
            "width": "auto",
            "margin-top": settings.paddingTop + "px",
            "margin-bottom": settings.paddingBottom + "px",
            "margin-left": settings.paddingLeft + "px",
            "margin-right": settings.paddingRight + "px",
            "overflow": "hidden",
            "padding": "0 0 0 0"
        }).html(htmlContent)
		  .appendTo(contentBox);

        if (!$.browser.msie && !$.browser.chrome) {
            contentInnerBox.height(settings.mainHeight - 2 * settings.borderWidth - settings.paddingTop - settings.paddingBottom);
        }

        // arrowLeft is the distance from the left edge of the callout to the arrow.
        // offsetLeft is the distance from the left edge of the screen to where the callout should appear.

        settings.targetOffset = settings.target.offset();
        if (settings.align.toLowerCase() == "right") {
            settings.arrowLeft = settings.width - settings.arrowHeight - settings.arrowInset - settings.paddingRight;
            settings.offsetLeft = settings.targetOffset.left + settings.nudgeHorizontal + settings.target.width() - settings.width;
        }
        else {  // left
            settings.arrowLeft = settings.arrowInset;
            settings.offsetLeft = settings.targetOffset.left + settings.nudgeHorizontal;
        }

        // Create the two divs necessary to implement the "thick-border technique" which results in 
        // the arrow shape without the use of images.
        var arrowDiv = $("<div />").css({
            "position": "absolute",
            "width": "0px",
            "height": "0px",
            "left": "0px",
            "top": "0px",
            "border-left-style": "dotted",
            "border-left-color": "transparent",
            "border-right-style": "dotted",
            "border-right-color": "transparent",
            "margin-left": settings.arrowLeft + "px",
            "z-index": settings.zIndex + 2,
            "border-width": (2 * settings.borderWidth + settings.arrowHeight) + "px"
        });

        var arrowDivInner = $("<div />").css({
            "position": "relative",
            "left": -1 * settings.arrowHeight + "px",
            "height": "0px",
            "width": "0px",
            "border-width": settings.arrowHeight + "px",
            "border-left-style": "dotted",
            "border-right-style": "dotted",
            "border-left-color": "transparent",
            "border-right-color": "transparent",
            "z-index": settings.zIndex + 1
        }).appendTo(arrowDiv);

        if (settings.orient.toLowerCase() == "below") {
            $(arrowDiv).css({
                "border-top": "none",
                "border-bottom": "solid " + (settings.arrowHeight + 2 * settings.borderWidth) + "px " + settings.borderColor,
                "top": "0px"
            }).prependTo(mainBox);

            $(arrowDivInner).css({
                "border-top-style": "none",
                "top": 2 * settings.borderWidth + "px",
                "border-bottom": settings.arrowHeight + "px solid " + settings.backColor
            });

            contentBox.css("top", settings.arrowHeight + settings.borderWidth);

            settings.offsetTop = settings.targetOffset.top + settings.target.height() + settings.nudgeVertical;
        } else { // below
            $(arrowDiv).css({
                "border-bottom": "none",
                "border-top-style": "solid",
                "border-top-width": (settings.arrowHeight + 2 * settings.borderWidth) + "px",
                "border-top-color": settings.borderColor,
                "top": settings.mainHeight - settings.borderWidth + "px"
            }).appendTo(mainBox);

            $(arrowDivInner).css({
                "border-bottom-style": "none",
                "top": -1 * (2 * settings.borderWidth + settings.arrowHeight) + "px",
                "border-top": settings.arrowHeight + "px solid " + settings.backColor
            });

            settings.offsetTop = settings.targetOffset.top - (settings.mainHeight + settings.arrowHeight) + settings.nudgeVertical;
        }

        // Create a div to serve as the border.  This box must have a z-index less than mainContent box.
        if (settings.borderWidth > 0) {
            var borderBox = $("<div />").width(settings.width).css({
                "position": "absolute",
                "display": "none",
                "z-index": settings.zIndex - 1, // The borderBox needs to be beneath the contentBox
                "background-color": settings.borderColor,
                "left": settings.offsetLeft + "px",
                "top": settings.offsetTop + (settings.orient == "below" ? settings.arrowHeight + settings.borderWidth : 0) + "px"
            }).prependTo(settings.region ? settings.region : "body");

            // Need a shim in the borderBox to prop it up to the correct height.
            var shimHeight = settings.mainHeight;
            if ($.browser.msie || $.browser.chrome) {
                shimHeight -= (2 * settings.cornerRadius);
            }

            borderBox.append($("<div />").height(shimHeight));
        }

        // Position the container correctly.
        $(containerBox).css({
            "left": settings.offsetLeft + "px",
            "top": settings.offsetTop + "px"
        });

        // Apply the rounded corners if necessary.
        if (settings.cornerRadius > 0) {
            if (borderBox) {
                borderBox.corners(settings.cornerRadius + "px");
                $(contentBox).corners(settings.cornerRadius - settings.borderWidth + "px");
                settings.borderBox = borderBox;
            }
            else {
                $(contentBox).corners(settings.cornerRadius + "px");
            }
        }

        // If a callback function was provided, hide the container and call the function.
        if (typeof (settings.showCallback) == "function") {
            settings.showCallback.apply(containerBox, [settings]);
        } else {
            containerBox.show();
            if (borderBox) { borderBox.show(); }
        }

        // Store the container in the targets data store so we can access it in the close method.
        settings.target.data("__callout", [containerBox, borderBox]);

        return this;
    };

    $.browser.chrome = navigator.userAgent.toLowerCase().indexOf('chrome') > -1;

    $.fn.pixels = function(cssAttr) {
        var val = $(this).css(cssAttr);
        var i = val.indexOf("px");
        if (i == -1) { return 0; }

        return parseFloat(val.substr(0, i));
    };

    $.fn.closeCallout = function() {
        return $(this).each(function() {
            // Remove the callout from the DOM.
            var calloutSet = $(this).data("__callout");
            if (calloutSet == null) { return; }

            $.each(calloutSet, function() {
                $(this).remove();
            });
            $(this).data("__callout", null);
        });
    };

})(jQuery);
