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

function doRemoveEditor() {
  $("#progress").html("Working…");
  
  var data = new FormData($("#mainform")[0]);
  
  for (const file of document.getElementById("original").files) {
    data.append("original", file);
  }
  for (const file of document.getElementById("remove").files) {
    data.append("remove", file);
  }
  
  var url = "collectionremove";
  
  $.ajax({
    url: url,
    data: data,
    cache: false,
    contentType: false,
    processData: false,
    method: "POST",
    success: function(response) {
      console.log("success");
      
      download("collection-removed.csv", response.output, "text/csv");
      $("#progress").html(('<br>' + response.status + "\n\n" + response.notFoundOutput).replace(/(?:\r\n|\r|\n)/g, '<br>'));
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
	
	var url = "box" + "/" + setCode + "?outputformat=cardlist&tokens=false";
	
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
	
	var url = "box" + "/" + setCode + "?outputformat=cardlist&tokens=false&boosters=" + packCount;
	
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
	
	var url = "pre/" + setCode + "?outputformat=cardlist&tokens=false&extendedart=false";
	
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

function loadDraftmancerCards() {
  $.ajax({
    url: "draftmancercards",
    data: null,
    cache: false,
    contentType: false,
    processData: false,
    method: "GET",
    success: function(response) {
      console.log("success:");
      console.log(response);
      
      var tabs = document.getElementById('tabs');
      var tabsDraftable = document.getElementById('tabs-draftable');
      for(var i = 0; i<response.length; i++) {
        const cardset = response[i];
        
        if (cardset.display_reversed) {
          cardset.cards.reverse();
        }
        
        var button = document.createElement('button');
        button.innerHTML = cardset.name;
        button.onclick = function() {
          setDraftmancerCardSet(cardset);
        };
        (cardset.is_draftable ? tabsDraftable : tabs).appendChild(button);
      }
      
      if (window.location.hash) {
        var index = response.findIndex(cardset => cardset.name == decodeURI(window.location.hash.substring(1)));
        setDraftmancerCardSet(response[index] || response[0]);
      } else {
        var index = response.findIndex(cardset => cardset.name == "Custom Cards");
        setDraftmancerCardSet(response[index] || response[0]);
      }
      
      document.getElementById('loading').hidden = true;
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

String.prototype.capitalize = function() {
  return this.charAt(0).toUpperCase() + this.slice(1);
}

var currentCardset;

function toggleViewMode() {
  localStorage.setItem("showDetails", !(localStorage.getItem("showDetails") === 'true'))
  
  setDraftmancerCardSet(currentCardset);
}

function setDraftmancerCardSet(cardset) {
  document.getElementById("cardset-title").innerHTML = cardset.name;
  currentCardset = cardset;
  
  var p = document.getElementById("download-button");
  p.innerHTML = "";
  
  // Download button
  if (cardset.string) {
    var button = document.createElement("button");
    button.innerHTML = "Download Draftmancer File"
    button.onclick = function() {
      download(cardset.name + ".txt", cardset.string, "text/plain");
    };
    p.appendChild(button);
  }
  
  // Setup table
  
  var table = document.getElementById("cardtable");
  table.innerHTML = "<style>th, td { padding-block: 2px; padding-inline: 4px } </style>";
  
  var cards = cardset.cards;
  
  if (localStorage.getItem("showDetails") === 'true') {
    for(var i=0; i <cards.length; i++) {
      var element = cards[i];
      
      var row1 = document.createElement("tr");
      table.appendChild(row1);
      
      var imageData = document.createElement("td");
      row1.appendChild(imageData);
      imageData.setAttribute("rowspan", 4);
      
      var imageURL = element.image || element.image_uris["en"];
      imageData.innerHTML = "<div><a href=\"" + imageURL + "\"><img src=\"" + imageURL + "\" height=264 width=189 style='border-radius:10px;'></a></div>";
      
      var nameData = document.createElement("td");
      row1.appendChild(nameData);
      nameData.innerHTML = "<h3>" + element.name + "</h3>";
      
      var manaCostData = document.createElement("td");
      manaCostData.setAttribute("align", "right");
      row1.appendChild(manaCostData);
      manaCostData.innerHTML = "<h3>" + (element.mana_cost || "") + "</h3>";
      
      var row2 = document.createElement("tr");
      table.appendChild(row2);
      
      var typeData = document.createElement("td");
      row2.appendChild(typeData);
      var type = element.type || "";
      if (element.subtypes) {
        type += " — " + element.subtypes.join(" ");
      }
      typeData.innerHTML = "<h4>" + type + "</h4>";
      
      var rarityData = document.createElement("td");
      rarityData.setAttribute("align", "right");
      row2.appendChild(rarityData);
      var rarity = "";
      if (element.rarity) {
        rarity = " (" + Array.from(element.rarity)[0].toUpperCase() + ")";
      }
      rarityData.innerHTML = "<h4>" + element.set.toUpperCase() + " #" + element.collector_number + rarity + "</h4>";
      
      var row3 = document.createElement("tr");
      table.appendChild(row3);
      
      var textData = document.createElement("td");
      textData.setAttribute("width", 1000);
      textData.setAttribute("colspan", 2);
      row3.appendChild(textData);
      if (element.oracle_text) {
        textData.innerHTML = element.oracle_text.replace(/\n/g, "<br />") || "";
      }
      
      var row4 = document.createElement("tr");
      table.appendChild(row4);
      
      var artistData = document.createElement("td");
      row4.appendChild(artistData);
      if (element.artist) {
        artistData.innerHTML = "Illustrated by: " + element.artist;
      }
      
      var ptLoyaltyData = document.createElement("td");
      row4.appendChild(ptLoyaltyData);
      var ptLoyalty = element.loyalty || "";
      if (element.power != undefined && element.toughness != undefined) {
        ptLoyalty = element.power.toString() + "/" + element.toughness.toString();
      }
      ptLoyaltyData.setAttribute("colspan", 2);
      ptLoyaltyData.setAttribute("align", "right");
      ptLoyaltyData.innerHTML = "<h3>" + ptLoyalty + "</h3>";
    }
    
    while (dataCount < rowCount) {
      var data = document.createElement("td");
      row.appendChild(data);
      dataCount += 1;
    }
  } else {
    var dataCount = 0;
    var rowCount = 6;
    var row = document.createElement("tr");
    table.appendChild(row);
    
    for(var i=0; i <cards.length; i++) {
      var element = cards[i];
      
      var data = document.createElement("td");
      
      var rarity = "";
      if (element.rarity) {
        rarity = " (" + Array.from(element.rarity)[0].toUpperCase() + ")";
      }
      
      var imageURL = element.image || element.image_uris["en"];
      data.innerHTML = "<center><div><a href=\"" + imageURL + "\"><img src=\"" + imageURL + "\" height=264 width=189 style='border-radius:10px;'></a></div><p>" + element.name + "<br>" + element.set.toUpperCase() + " #" + element.collector_number + rarity + "</p><br></center>";
      
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
  }
  
  window.location.hash = cardset.name;
  
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

var deckResponse;
var deckFilter = [];

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
			
			deckResponse = response;
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
			
			setupDecksTable();
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

function setupDecksTable() {
	updateChecks();
	
	var exact = document.getElementById("exactCheck").checked;
	
	var booster = deckResponse.filter((deck) => {
		
		if (!exact && deckFilter.length == 0) {
			return true;
		}
		
		var containedCount = 0;
		
		for (var i = 0; i < deck.ci.length; i++) {
			var char = deck.ci[i];
			if (deckFilter.includes(char)) {
				containedCount += 1;
			} else if (exact) {
				return false;
			}
		}
		
		return containedCount >= deckFilter.length;
	});
	
	var table = document.getElementById("cardtable");
	
	table.innerHTML = "";
	
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
}

function filterToggle(color) {
	var index = deckFilter.indexOf(color);
	
	if (index == -1) {
		deckFilter.push(color);
	} else {
		deckFilter.splice(index, 1);
	}
	
	setupDecksTable();
}

function updateChecks() {
	var colors = ["W", "U", "B", "R", "G"];
	
	for (var i = 0; i < colors.length; i++) {
		var color = colors[i];
		var id = "check" + color;
		var element = document.getElementById(id);
		console.log(id);
		
		if (deckFilter.includes(color)) {
			element.style.opacity = 1;
		} else {
			element.style.opacity = 0.3;
		}
	}
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
