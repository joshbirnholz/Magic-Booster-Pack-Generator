function download(filename, text, mimetype = "text/plain") {
	var pom = document.createElement('a');
	pom.setAttribute('href', 'data:' + mimetype + ';charset=utf-8,' + encodeURIComponent(text));
	pom.setAttribute('download', filename);
	
	if (document.createEvent) {
		var event = document.createEvent('MouseEvents');
		event.initEvent('click', true, true);
		pom.dispatchEvent(event);
	}
	else {
		pom.click();
	}
}

function downloadFromURL(filename, fromURL) {
	var pom = document.createElement('a');
	pom.setAttribute('href', fromURL);
	pom.setAttribute('download', filename);
	
	if (document.createEvent) {
		var event = document.createEvent('MouseEvents');
		event.initEvent('click', true, true);
		pom.dispatchEvent(event);
	}
	else {
		pom.click();
	}
}

function doDownloadBox(sorted) {
	var setCode = prompt("Enter a set code to download a booster box.");
	
	if (setCode === undefined || setCode === "" || setCode == null) {
		return;
	}
	
	$("#boxprogress").html("Working…");
	
	var url = "";
	
	if (sorted) {
		url = "boxingleague";
	} else {
		url = "box";
	}
	
	url += "/" + setCode;
	
	$.ajax({
		url: url,
		cache: false,
		contentType: false,
		processData: false,
		method: "GET",
		success: function(response) {
			console.log("success");
			console.log(response);
			
			var obj = JSON.parse(response);
			
			if (obj.error !== undefined) {
				alert(obj.error);
				$("#boxprogress").html("");
				return;
			}
			
			var formatted = downloadOutput(obj);
			download(setCode + " box.json", formatted, "application/json");
			$("#boxprogress").html("");
		},
		error: function(xhr, status, error) {
			console.log("error");
			console.log(xhr);
			console.log(status);
			console.log(error);
			
			alert(error);
			$("#boxprogress").html("");
		}
	})
}

function doDownloadBoxList() {
	var setCode = prompt("Enter a set code to download a booster box.");
	
	if (setCode === undefined || setCode === "" || setCode == null) {
		return;
	}
	
	$("#boxprogress").html("Working…");
	
	var url = "box" + "/" + setCode + "?cardlist=true";
	
	$.ajax({
		url: url,
		cache: false,
		contentType: false,
		processData: false,
		method: "GET",
		success: function(response) {
			console.log("success");
			console.log(response);
			
			var obj = JSON.parse(response);
			
			if (obj.error !== undefined) {
				alert(obj.error);
				$("#boxprogress").html("");
				return;
			}
			
			var formatted = downloadOutput(obj);
			download(setCode + " box.json", formatted, "application/json");
			$("#boxprogress").html("");
		},
		error: function(xhr, status, error) {
			console.log("error");
			console.log(xhr);
			console.log(status);
			console.log(error);
			
			alert(error);
			$("#boxprogress").html("");
		}
	})
}

function doDownloadPack() {
	var setCode = prompt("Enter a set code to download a booster pack.");
	
	if (setCode === undefined || setCode === "" || setCode == null) {
		return;
	}
	
	$("#boxprogress").html("Working…");
	
	var url = "pack/" + setCode;
	
	$.ajax({
		url: url,
		cache: false,
		contentType: false,
		processData: false,
		method: "GET",
		success: function(response) {
			console.log("success");
			console.log(response);
			
			var obj = JSON.parse(response);
			
			if (obj.error !== undefined) {
				alert(obj.error);
				$("#boxprogress").html("");
				return;
			}
			
			var formatted = downloadOutput(obj);
			download(setCode + " pack.json", formatted, "application/json");
			$("#boxprogress").html("");
		},
		error: function(xhr, status, error) {
			console.log("error");
			console.log(xhr);
			console.log(status);
			console.log(error);
			
			alert(error);
			$("#boxprogress").html("");
		}
	})
}

function doDownloadPrereleasePack() {
	var setCode = prompt("Enter a set code to download a prerelease pack.");
	
	if (setCode === undefined || setCode === "" || setCode == null) {
		return;
	}
	
	$("#boxprogress").html("Working…");
	
	var url = "pre/" + setCode;
	
	$.ajax({
		url: url,
		cache: false,
		contentType: false,
		processData: false,
		method: "GET",
		success: function(response) {
			console.log("success");
			console.log(response);
			
			var obj = JSON.parse(response);
			
			if (obj.error !== undefined) {
				alert(obj.error);
				$("#boxprogress").html("");
				return;
			}
			
			var formatted = downloadOutput(obj);
			download(setCode + " pack.json", formatted, "application/json");
			$("#boxprogress").html("");
		},
		error: function(xhr, status, error) {
			console.log("error");
			console.log(xhr);
			console.log(status);
			console.log(error);
			
			alert(error);
			$("#boxprogress").html("");
		}
	})
}

function doDownloadPrereleasePackList() {
	var setCode = prompt("Enter a set code to download a prerelease pack.");
	
	if (setCode === undefined || setCode === "" || setCode == null) {
		return;
	}
	
	$("#boxprogress").html("Working…");
	
	var url = "pre/" + setCode + "?cardlist=true";
	
	$.ajax({
		url: url,
		cache: false,
		contentType: false,
		processData: false,
		method: "GET",
		success: function(response) {
			console.log("success");
			console.log(response);
			
			var obj = JSON.parse(response);
			
			if (obj.error !== undefined) {
				alert(obj.error);
				$("#boxprogress").html("");
				return;
			}
			
			var formatted = downloadOutput(obj);
			download(setCode + " pack.json", formatted, "application/json");
			$("#boxprogress").html("");
		},
		error: function(xhr, status, error) {
			console.log("error");
			console.log(xhr);
			console.log(status);
			console.log(error);
			
			alert(error);
			$("#boxprogress").html("");
		}
	})
}

function doDownloadDeck() {
	$("#progress").html("Working…");
	
	var data = new FormData($("#mainform")[0]);
	
	data.append("deck", document.getElementById("deck").value);
	
	var url = "deck";
	
	if ($("#autofix").prop("checked") == true) {
		url += "?autofix=true"
	} else {
		url += "?autofix=false"
	}
	
	var cardBack = document.getElementById("back").value;
	
	if (cardBack !== "") {
		if (validURL(cardBack)) {
			url += "&back=" + cardBack;
		} else {
			alert("The card back image URL isn't valid.");
			$("#progress").html("");
			return
		}
	}
	
	$.ajax({
		url: url,
		data: data,
		cache: false,
		contentType: false,
		processData: false,
		method: "POST",
		success: function(response) {
			console.log("success");
			console.log(response);
			
			var obj = JSON.parse(response);
			
			if (obj.error !== undefined) {
				alert(obj.error);
				$("#progress").html("");
				return;
			}
			
			var formatted = downloadOutput(obj);
			download("deck.json", formatted, "application/json");
			$("#progress").html("");
		},
		error: function(xhr, status, error) {
			console.log("error");
			console.log(xhr);
			console.log(status);
			console.log(error);
			
			alert(error);
			$("#progress").html("");
		}
	})
}

function validURL(str) {
  var pattern = new RegExp('^(https?:\\/\\/)?'+ // protocol
    '((([a-z\\d]([a-z\\d-]*[a-z\\d])*)\\.)+[a-z]{2,}|'+ // domain name
    '((\\d{1,3}\\.){3}\\d{1,3}))'+ // OR ip (v4) address
    '(\\:\\d+)?(\\/[-a-z\\d%_.~+]*)*'+ // port and path
    '(\\?[;&a-z\\d%_.~+=-]*)?'+ // query string
    '(\\#[-a-z\\d_]*)?$','i'); // fragment locator
  return !!pattern.test(str);
}

function downloadOutput(obj) {
	if (obj.downloadOutput !== undefined) {
		return obj.downloadOutput;
	} else {
		return JSON.stringify(obj, null, 1);
	}
}
