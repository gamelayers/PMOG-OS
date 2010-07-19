
checked=false;

function checkedAll () 
{
	var aa= document.getElementById('tool_form');
	if (checked == false)
	{
		checked = true
	}
	else
	{
		checked = false
	}
	for (var i =0; i < aa.elements.length; i++) 
	{
		aa.elements[i].checked = checked;
	}
}

