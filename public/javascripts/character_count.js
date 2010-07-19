function charCounter(id, maxlimit, limited){
	if (!$('counter-'+id)){
		$(id).insert({after: '<div id="counter-'+id+'"></div>'});
	}
	if($F(id).length >= maxlimit){
		if(limited){	$(id).value = $F(id).substring(0, maxlimit); }
		$('counter-'+id).addClassName('charcount-limit');
		$('counter-'+id).removeClassName('charcount-safe');
	} else {	
		$('counter-'+id).removeClassName('charcount-limit');
		$('counter-'+id).addClassName('charcount-safe');
	}
	$('counter-'+id).update( $F(id).length + '/' + maxlimit );	
		
}

function makeItCount(id, maxsize, limited){
	if(limited == null) limited = true;
	if ($(id)){
		Event.observe($(id), 'keyup', function(){charCounter(id, maxsize, limited);}, false);
		Event.observe($(id), 'keydown', function(){charCounter(id, maxsize, limited);}, false);
		charCounter(id,maxsize,limited);
	}
}