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
	var setCode = $("#setlist option:selected").val();
	
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
		method: "POST",
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
	var setCode = $("#setlist option:selected").val();
	
	if (setCode === undefined || setCode === "" || setCode == null) {
		return;
	}
	
	$("#boxprogress").html("Working…");
	
	var url = "box" + "/" + setCode + "?outputformat=cardlist";
	
	$.ajax({
		url: url,
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
				$("#boxprogress").html("");
				return;
			}
			
			var formatted = downloadOutput(obj);
			download(setCode + " box.txt", formatted, "text/plain");
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

function doDownloadCustomNumPacksList(packCount) {
	var setCode = $("#setlist option:selected").val();
	
	if (setCode === undefined || setCode === "" || setCode == null) {
		return;
	}
	
	$("#boxprogress").html("Working…");
	
	var url = "box" + "/" + setCode + "?outputformat=cardlist&boosters=" + packCount;
	
	$.ajax({
		url: url,
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
				$("#boxprogress").html("");
				return;
			}
			
			var formatted = downloadOutput(obj);
			download(setCode + " packs.txt", formatted, "text/plain");
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

function doDownloadPack(packCount) {
	var setCode = $("#setlist option:selected").val();
	
	if (setCode === undefined || setCode === "" || setCode == null) {
		return;
	}
	
	$("#boxprogress").html("Working…");
	
	var url = "pack/" + setCode + "?count=" + packCount;
	
	$.ajax({
		url: url,
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

function doDownloadPrereleasePack(packCount) {
	var setCode = $("#setlist option:selected").val();
	
	if (setCode === undefined || setCode === "" || setCode == null) {
		return;
	}
	
	$("#boxprogress").html("Working…");
	
	var url = "pre/" + setCode + "?count=" + packCount;
	
	var seed = $("#seedlist").val();
	if (seed !== null) {
		url += "&seed=" + seed;
	}
	
	$.ajax({
		url: url,
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
	var setCode = $("#setlist option:selected").val();
	
	if (setCode === undefined || setCode === "" || setCode == null) {
		return;
	}
	
	$("#boxprogress").html("Working…");
	
	var url = "pre/" + setCode + "?outputformat=cardlist&extendedart=false";
	
	var seed = $("#seedlist").val();
	if (seed !== null) {
		url += "&seed=" + seed;
	}
	
	$.ajax({
		url: url,
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
				$("#boxprogress").html("");
				return;
			}
			
			var formatted = downloadOutput(obj);
			download(setCode + " prerelease pack.txt", formatted, "text/plain");
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
	
	var customOverrides = document.getElementById("customoverrides").value;
	url += "&customoverrides=" + customOverrides;
	
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
			
			$("#progress").html("");
			
			var filename = "deck";
			if (obj.filename !== undefined) {
				filename = obj.filename;
			}
			
			filename = prompt("Enter a file name for this deck.", filename);
			
			if (filename == null) {
				return;
			}
			
			download(filename + ".json", formatted, "application/json");
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

function loadSets() {
	$.ajax({
		url: "sets",
		data: null,
		cache: false,
		contentType: false,
		processData: false,
		method: "POST",
		success: function(response) {
			console.log("success");
			
			$("#setlist option[value='']").remove();
			
			var setlist = $("#setlist");
			
			response.forEach((element) => {
				var o = new Option(element.name, element.code);
				/// jquerify the DOM object 'o' so we can use the html method
				$(o).html(element.name);
				
				setlist.append(o);
			});
			
			updateSeeds();
		},
		error: function(xhr, status, error) {
			console.log("error");
			console.log(xhr);
			console.log(status);
			console.log(error);
			
			alert(error);
		}
	})
}

function loadCustomCards() {
	$.ajax({
		url: "customcards",
		data: null,
		cache: false,
		contentType: false,
		processData: false,
		method: "GET",
		success: function(response) {
			console.log("success");
			
			var table = document.getElementById("cardtable");
			
			var dataCount = 0;
			var rowCount = 6;
			var row = document.createElement("tr");
			table.appendChild(row);
			
			for(var i=response.length-1; i >=0; i--) {
				var element = response[i];
				
				var data = document.createElement("td");
				var num = i+1;
				data.innerHTML = "<center><div><a href='" + element.imageURL + "'><img src='" + element.imageURL + "' height=264 width=189 style='border-radius:10px;'></a></div><p>" + element.name + "<br>#" + num + "</p><br></center>";
				
				row.appendChild(data);
				dataCount += 1;
				if (dataCount >= rowCount) {
					table.appendChild(row);
					row = document.createElement("tr");
					table.appendChild(row);
					dataCount = 0;
				}
			}
			
			while (dataCount < rowCount) {
				var data = document.createElement("td");
				row.appendChild(data);
				dataCount += 1;
			}
		},
		error: function(xhr, status, error) {
			console.log("error");
			console.log(xhr);
			console.log(status);
			console.log(error);
			
			alert(error);
		}
	})
}

function loadSetTest(setCode, seed) {
	var url = "pack/" + setCode + "?outputformat=json&extendedart=false";
	
	if (seed !== null && seed !== undefined) {
		url += "&seed=" + seed;
	}
	
	$.ajax({
		url: url,
		data: null,
		cache: false,
		contentType: false,
		processData: false,
		method: "POST",
		success: function(response) {
			console.log("success");
			
			var booster = JSON.parse(response);
			console.log(booster);
			
			var table = document.getElementById("cardtable");
			
			var dataCount = 0;
			var rowCount = 5;
			var row = document.createElement("tr");
			table.appendChild(row);
			
			for(var i=0; i <= booster.length; i++) {
				var element = booster[i];
				
				var data = document.createElement("td");
				var num = i+1;
				
				var html = "<div class='container'><a href='" + element.scryfallURI + "'><img src='" + element.imageURL + "' height=264 width=189 style='border-radius:10px;' class='image'>";
				
				if (element.foil) {
					html += "<div class='overlay'><img src='HQ-foiling-card.png' class='image'></div>";
				}
				
				html += "</a></div>";
				
				data.innerHTML = html;
				
				row.appendChild(data);
				dataCount += 1;
				if (dataCount >= rowCount) {
					table.appendChild(row);
					row = document.createElement("tr");
					table.appendChild(row);
					dataCount = 0;
				}
			}
			
			while (dataCount < rowCount) {
				var data = document.createElement("td");
				row.appendChild(data);
				dataCount += 1;
			}
		},
		error: function(xhr, status, error) {
			console.log("error");
			console.log(xhr);
			console.log(status);
			console.log(error);
			
			alert(error);
		}
	})
}

function locationForDeck(deck) {
	var location = deck.url;
	
	if (deck.revision !== null && deck.revision !== undefined) {
		location += "?revision=" + deck.revision;
	}
	
	location += "#show__spoiler";
	
	return location;
}

function loadDecks() {
	var url = "decks";
	
	$.ajax({
		url: url,
		data: null,
		cache: false,
		contentType: false,
		processData: false,
		method: "GET",
		success: function(response) {
			console.log("success");
			
			var booster = response;
			console.log(booster);
			const urlSuffix = "#show__spoiler";
			
			const linkID = getParameterByName("id");
			if (linkID !== null) {
				const found = booster.find(element => element.ids.includes(linkID));
				const location = locationForDeck(found);
				
				if (found !== undefined) {
					window.location.replace(location);
					return;
				}
			}
			
			var table = document.getElementById("cardtable");
			
			var dataCount = 0;
			var colCount = 2;
			var row = document.createElement("tr");
			table.appendChild(row);
			table.style.borderSpacing = "10px";
			
			var decks = booster.filter(deck => deck.type === undefined);
			var duals = booster.filter(deck => deck.type !== undefined);
			decks.push(...duals);
			
			for(var i=0; i < decks.length; i++) {
				var element = decks[i];
				
				var data = document.createElement("td");
				var location = locationForDeck(element);
				
				var html = "<div class='container'><a style='text-decoration: none;' href='" + location + "'>";
				
				html += "<img src='" + element.front + "' style='";
				
				if (element.back !== undefined) {
					html += "width:49%;";
				}
				
				html += "border-radius:10px;max-width:189px;max-height:264px' class='image'>";
				
				if (element.back !== undefined) {
					if (dataCount > 0) {
						table.appendChild(row);
						row = document.createElement("tr");
						table.appendChild(row);
						dataCount = 0;
					}
					
					data.colSpan = 2;
					dataCount += 1;
					data.style.padding = "8px";
					data.style.borderRadius = "10px";
					data.style.backgroundColor = "lightGray";
					data.style.border = "2px solid #BBBBBB";
					html += " <img src='" + element.back + "' style='width:49%;border-radius:10px;max-width:189px;max-height:264px' class='image'>";
					html += "</a></div>";
					
					if (element.type == "partners") {
						html += "<div style='text-align:center;font-style:italic;'>Partners</div>";
					} else if (element.type == "dfc") {
						html += "<div style='width:50%; display:inline-block;text-align:center;font-style: italic;'>Front</div><div style='width:50%; display:inline-block;text-align:center;font-style:italic;'>Back</div>";
					}
				} else {
					html += "</a></div>";
					
					if (element.comment !== undefined) {
						html += "<div style='text-align:center;'>" + element.comment + "</div>";
					}
				}
				
				data.innerHTML = html;
				
				row.appendChild(data);
				dataCount += 1;
				
				if (dataCount >= colCount) {
					table.appendChild(row);
					row = document.createElement("tr");
					table.appendChild(row);
					dataCount = 0;
				}
			}
			
			while (dataCount < colCount) {
				var data = document.createElement("td");
				row.appendChild(data);
				dataCount += 1;
			}
		},
		error: function(xhr, status, error) {
			console.log("error");
			console.log(xhr);
			console.log(status);
			console.log(error);
			
			alert(error);
		}
	})
}

function addCustomCard(number) {
	var box = document.getElementById('customoverrides');
	
	if (box.value !== "") {
		if (!box.value.endsWith(";")) {
			box.value += ";";
		}
		box.value += number;
	} else {
		box.value = number;
	}
	
}

function loadCustomCardsList() {
	$.ajax({
		url: "customcards",
		data: null,
		cache: false,
		contentType: false,
		processData: false,
		method: "GET",
		success: function(response) {
			var div = document.getElementById("customlist");
			var shownCards = 5;
			
			var offset = 1;
			var elements = response.map((element) => {
				element.offset = offset;
				offset += 1;
				return element;
			});
			var newest = elements.slice(Math.max(response.length - shownCards, 0));
			var objects = newest.reverse().map((element) => {
//				return element.name;
				
				var baseW = 63;
				var baseH = 88;
				
				var smallScale = 2;
				var zoomScale = 5;
				
				return "<a class='thumbnail' href='javascript:addCustomCard(" + element.offset +");'><img style='border-radius:7px;' src='" + element.imageURL + "' width='" + (baseW*smallScale) +"px' height='" + (baseH*smallScale) + "px' border='0' /><span><img style='border-radius:17px;' src='" + element.imageURL + "' width='" + (baseW*zoomScale) +"px' height='" + (baseH*zoomScale) + "px' /></span></a>"
			});
			div.innerHTML = objects.join(" ");
		},
		error: function(xhr, status, error) {
			
		}
	})
}

function loadSeeds() {
	$.ajax({
		url: "seeds",
		data: null,
		cache: false,
		contentType: false,
		processData: false,
		method: "GET",
		success: function(response) {
			$("#seedlistall option[value='']").remove();
			
			Object.keys(response).forEach((setCode) => {
				var seeds = response[setCode];
				seeds.forEach((seed) => {
					var name = "Prerelease Pack: " + seed.name;
					name += " ";
					var colors = seed.colors.join('/');
					name += "(" + colors + ")";
					
					var value = seed.set + "-" + seed.name;
					
					var o = new Option(name, value);
					/// jquerify the DOM object 'o' so we can use the html method
					$(o).html(name);
					$(o).attr("id", value);
					
					$("#seedlistall").append(o);
				});
			});
			
			updateSeeds();
		},
		error: function(xhr, status, error) {
			
		}
	})
}

function updateSeeds() {
	var selectedSet = $("#setlist").val();
	
	var found = false;
	var seedlist = $("#seedlist");
	var allSeedlist = $("#seedlistall");
	
	var select = document.getElementById("seedlist");
	var length = select.options.length;
	for (i = length-1; i >= 0; i--) {
	  select.options[i] = null;
	}
	
	allSeedlist.children().each(function () {
		var option = document.getElementById(this.id);
		
		if (this.value.startsWith(selectedSet + "-")) {
			var clone = option.cloneNode(true);
			
			if (!found) {
				clone.selected = true;
			}
			
			found = true;
			
			seedlist.append(clone);
		}
	});
	
	if (!found) {
		seedlist.hide();
	} else {
		seedlist.show();
	}
	
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

function getParameterByName(name, url = window.location.href) {
	name = name.replace(/[\[\]]/g, '\\$&');
	var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'),
		results = regex.exec(url);
	if (!results) return null;
	if (!results[2]) return '';
	return decodeURIComponent(results[2].replace(/\+/g, ' '));
}
