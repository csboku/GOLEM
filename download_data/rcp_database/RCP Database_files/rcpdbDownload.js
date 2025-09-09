var varTree, scenTree, regTree;
var dGrid;
var WLC1 = 200;
var WLC2 = 200;
var chaH1 = 200;
var chaW1 = 300;
var vId = "";
var vYear=2000;
var loginRequest;
var theVarModel = "";
var theScenModel = "";
var theRegModel = "";
var myDebug = false;
function loadAll(m1, m2) {
	theVarModel = m1;
	theScenModel = m1;
	// navigation tabs
	Nifty("ul#nav a", "transparent top");
	doResize();
	//
	//populate regionall downlaod table
	rfrm = document.getElementById('regional');
	rfrm.src = "dsd?Action=bulklist"
	//
	//populate spatial downlaod table
	tfrm = document.getElementById('spdl1');
	if (tfrm != null) {
		tfrm.src = "dsd?Action=downloadslist"
	}

	if (myDebug) {
		alert("done loadAll");
	}
}
function helpTriggerEnter() {
	helpElem = document.getElementById('help_area_container');
	helpElem.style.visibility = "visible";
	//alert ("helpTriggerEnter");
}
function helpTriggerLeave() {
	helpElem = document.getElementById('help_area_container');
	helpElem.style.visibility = "hidden";
	//alert ("helpTriggerLeave");
}
function doResize() {
	bh3 = document.body.clientHeight;
	bw3 = document.body.clientWidth;

	headerElem = document.getElementById('header');
	footerElem =  document.getElementById('footer');
	hHeader = headerElem.offsetHeight;
	if (window.ActiveXObject) { // IE
		hFooter = 22;
		footerElem.style.height = hFooter;
	} else {
		hFooter = 26;
		hFooter = footerElem.offsetHeight;
	}

	//hTree = (bh3 - hHeader - hFooter - 6)/2;
	hTree = (bh3 - hHeader - hFooter - 6)/10*5;
	hCont = (bh3 - hHeader - hFooter - 6)/10*5;
	wTree = (bw3 - 4);

	headerElem.style.width = wTree;
	footerElem.style.width = wTree;

	contentDiv = document.getElementById('content');
	if (contentDiv != null) {
		contentDiv.style.left = (2);
		contentDiv.style.top = (hTree + hHeader + 2);
		contentDiv.style.height = hCont;
		contentDiv.style.width = wTree; 
	} else {
		hTree = (bh3 - hHeader - hFooter - 6);
		//hCont = (bh3 - hHeader - hFooter - 6);
	}

	bulkDiv = document.getElementById('bulk_zone');
	bulkDiv.style.top = (hHeader + 3);
	bulkDiv.style.left = 2;
	bulkDiv.style.height = hTree;
	bulkDiv.style.width = wTree - 6;

	baDiv = document.getElementById('bulk_area_container');
	//tabDiv = document.getElementById('result_area_container');
	helpDiv = document.getElementById('help_area_container');

	baDiv.style.left = 0;
	baDiv.style.top = 0; 
	baDiv.style.height = hTree * 4/4 - 4;
	if (window.ActiveXObject) { // IE
		baDiv.style.width = wTree - 18 - 6 - 4;
	} else {
		baDiv.style.width = wTree - 18 - 6 - 4;
	}
	
	///if (tabDiv != null) {
	//	tabDiv.style.left = 0;
	//	tabDiv.style.top = 0;
	//	tabDiv.style.height = hCont - 4;
	//	tabDiv.style.width = wTree - 20;
	//}

	if (helpDiv != null) {
		helpDiv.style.top = hCont - 20 - 80 - 4;
		helpDiv.style.height = 80 + 22;
		helpDiv.style.left = (wTree)/2 + 2;
		helpDiv.style.width = (wTree)/2 - 1;
	}
}
			
function doOnSubTreeClick(subid) {
	varId  =  varTree.getSelectedItemId();
	if (varId) {
		doOnTreeClick(varId);
	}
}

function doOnTreeClick(id){
	vId = id;
	var descData = varTree.getUserData(id,"desc")||varTree.getItemText(id);
	var fileData = varTree.getUserData(id,"file");
	var descDiv;
	if (descData) {
		scenId = scenTree.getSelectedItemId()||"b2_base";

		czdiv = document.getElementById('content');
		descDiv = document.getElementById("description_zone");
		descDiv.childNodes.item(0).data=id+": "+descData;
		regDiv = document.getElementById("region_info_zone");
		regDiv.childNodes.item(0).data="Selected region(s): "+"World";
		scenDiv = document.getElementById("scenario_info_zone");
		scenDiv.childNodes.item(0).data="Selected scenario(s): "+scenId;
		// fill chart
		loadCdf();
	}
	if (fileData) {
		//window.open(fileData+"")
	}
	varTree.selectItem(id, false);
}

function loadCdf() {
	//
	// fill data chart
	scenId = scenTree.getSelectedItemId()||"b2_base";
	cdiv = document.getElementById('fig1div');
	h = Math.round(chaH1)-20; //cfrm.offsetHeight;
	w = Math.round(chaW1)+4//-10; //cfrm.offsetWidth;
	//swfurl = "dsd?Action=cdf&regions=World&scenarios="+scenId+"&variable="+id+"&width="+w+"&height="+h
	imgurl = "dsd?Action=cdf&regions=World&scenarios="+scenId+"&variable="+vId+"&year="+vYear+"&width="+w+"&height="+h
	//swftext = "<iframe width='"+w+"' height='"+h+"' border=0 marginheight='0' marginwidth='0' frameborder='0'" +
	//		  " src='"+swfurl+"'/>" ;
	ihtmltext = "<img src='"+imgurl+"'> </img>";
	document.getElementById('fig1div').innerHTML = ihtmltext;
}

function processNoteStateChange() {
	if (noteRequest.readyState == 4) { // Complete
		//alert("loginRequest: " + loginRequest.responseText);
		if (noteRequest.status == 200) { // OK response
			respText =  noteRequest.responseText;
			document.getElementById("description_area_content").innerHTML = respText;
		} else {
			alert("Problem: " + noteRequest.statusText);
		}
	}
}

<!-- == year selection stuff ============================================= -->
<!-- Original:  Ricocheting (ricocheting@hotmail.com) -->
<!-- Web Site:  http://www.ricocheting.com -->
<!-- This script and many more are available free online at -->
<!-- The JavaScript Source!! http://javascript.internet.com -->
<!-- Begin -->
var rotate_delay = 3000; // delay in milliseconds (5000 = 5 secs)
current = 0;
function next() {
	if (document.slideform.slide[current+1]) {
		vYear = document.slideform.slide[current+1].value;
		loadCdf();
		document.slideform.slide.selectedIndex = ++current;
	}
	else first();
}
function previous() {
	if (current-1 >= 0) {
		vYear = document.slideform.slide[current-1].value;
		loadCdf();
		document.slideform.slide.selectedIndex = --current;
	}
	else last();
}
function first() {
	current = 0;
	vYear = document.slideform.slide[current].value;
	loadCdf();
	document.slideform.slide.selectedIndex = current;
}
function last() {
	current = document.slideform.slide.length-1;
	vYear = document.slideform.slide[current].value;
	loadCdf();
	document.slideform.slide.selectedIndex = current;
}
function ap(text) {
	document.slideform.slidebutton.value = (text == "Stop") ? "Start" : "Stop";
	rotate();
}
function change() {
	current = document.slideform.slide.selectedIndex;
	vYear = document.slideform.slide[current].value;
	loadCdf();
}
function rotate() {
	if (document.slideform.slidebutton.value == "Stop") {
		current = (current == document.slideform.slide.length-1) ? 0 : current+1;
		vYear = document.slideform.slide[current].value;
		loadCdf();
		document.slideform.slide.selectedIndex = current;
		window.setTimeout("rotate()", rotate_delay);
	}
}
//  End 
