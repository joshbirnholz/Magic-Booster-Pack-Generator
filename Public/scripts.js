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
  
  if ($("#omenpath").prop("checked") == true) {
    url += "&omenpath=true"
  } else {
    url += "&omenpath=false"
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
			
      showFilenameModal(filename, formatted);
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

let pendingDownload = {
  suggestedName: "",
  content: "",
};

function showFilenameModal(suggestedName, content) {
  pendingDownload.suggestedName = suggestedName;
  pendingDownload.content = content;
  
  var checkbox = document.getElementById("saveCheckbox");
  var checkboxDiv = document.getElementById("saveCheckboxDiv");
  if (isValidHttpUrl(document.getElementById("deck").value)) {
    checkboxDiv.hidden = false;
    checkbox.checked = true;
  } else {
    checkboxDiv.hidden = true;
    checkbox.checked = false;
  }

  document.getElementById("filenameInput").value = suggestedName;
  document.getElementById("filenameModal").style.display = "block";
  document.getElementById("filenameBackdrop").style.display = "block";
  document.getElementById("filenameInput").focus();
}

function cancelFilenameModal() {
  document.getElementById("filenameModal").style.display = "none";
  document.getElementById("filenameBackdrop").style.display = "none";
}

function confirmFilenameModal() {
  const filename = document.getElementById("filenameInput").value.trim();
  const shouldSave = document.getElementById("saveCheckbox").checked;

  if (!filename) {
    alert("Please enter a name.");
    return;
  }

  if (shouldSave && isValidHttpUrl(document.getElementById("deck").value)) {
    saveDeckToHistory(filename); // Assumes this function is already defined
  }

  download(filename + ".json", pendingDownload.content, "application/json");
  cancelFilenameModal();
}

function isValidHttpUrl(string) {
  let url;
  
  try {
    url = new URL(string);
  } catch (_) {
    return false;
  }

  return url.protocol === "http:" || url.protocol === "https:";
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
  loadCardSymbols();
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
        button.className = 'cc-tab-btn';
        button.textContent = cardset.name;
        button.onclick = function() {
          setDraftmancerCardSet(cardset);
        };
        (cardset.is_draftable ? tabsDraftable : tabs).appendChild(button);
      }
      const urlParams = new URLSearchParams(window.location.search);
      const query = urlParams.get('q');
      
      if (query) {
        document.getElementById("search-input").value = query;
        loadSearchResults(query);
      } else if (window.location.hash) {
        var index = response.findIndex(cardset => cardset.name == decodeURI(window.location.hash.substring(1)));
        setDraftmancerCardSet(response[index] || response[0]);
      } else {
        var index = response.findIndex(cardset => cardset.name == "Custom Cards");
        setDraftmancerCardSet(response[index] || response[0]);
      }
      
      document.getElementById('loading').hidden = true;
      document.getElementById('search-form').hidden = false;
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

function loadSearchResults(query) {
  document.getElementById('loading').hidden = false;
  document.getElementById('cardtable').innerHTML = "";

  $.ajax({
    url: `custom/cards/search?q=${query}`,
    data: null,
    cache: false,
    contentType: false,
    processData: false,
    method: "GET",
    success: function(response) {
      document.getElementById('loading').hidden = true;
      
      console.log("success:");
      console.log(response);
      
      var cardset = {
        "cards": response.data,
        "display_reversed": false,
        "is_draftable": false,
        "name": `${response.total_cards} cards`,
        "is_search": true,
        "query": query
      };
      
      setDraftmancerCardSet(cardset);
      
      document.getElementById('query-description').innerText = `${response.total_cards} cards where ${response.query_description}`;
    },
    error: function(xhr, status, error) {
      document.getElementById('loading').hidden = true;

      // The search endpoint mimics Scryfall and returns 404 when nothing matches.
      // Show an empty "0 cards where …" result inline instead of a popup.
      if (xhr.status === 404) {
        var description = query;
        try {
          var body = xhr.responseJSON || JSON.parse(xhr.responseText);
          if (body && body.query_description) {
            description = body.query_description;
          }
        } catch (e) {}

        var cardset = {
          "cards": [],
          "display_reversed": false,
          "is_draftable": false,
          "name": "0 cards",
          "is_search": true,
          "query": query
        };
        setDraftmancerCardSet(cardset);
        document.getElementById('query-description').innerText = `0 cards where ${description}`;
        return;
      }

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
var currentRarity;

function toggleViewMode() {
  localStorage.setItem("showDetails", !(localStorage.getItem("showDetails") === 'true'))
  
  setDraftmancerCardSet(currentCardset);
}

function escapeHTML(value) {
  return String(value == null ? "" : value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

// Maps a Scryfall symbol code (e.g. "{W}", "{T}", "{G/U}") to its SVG URL.
// Populated dynamically from Scryfall's symbology endpoint so that newly added
// symbols render here without any code changes.
var cardSymbols = {};

/// Fetches the full list of card symbols from Scryfall and re-renders whatever
/// is currently on screen once they arrive. A cached copy from a previous visit
/// is applied immediately so symbols appear on first paint without waiting.
function loadCardSymbols() {
  function apply(data) {
    if (!data) return;
    data.forEach(function(symbol) {
      if (symbol.symbol && symbol.svg_uri) {
        // Mana symbols (any color/hybrid/phyrexian/generic) plus the tap and
        // untap symbols get a drop shadow to match Scryfall's "coin" look.
        // Other inline symbols (energy, planeswalker, etc.) stay flat.
        var shadow = symbol.represents_mana === true ||
                     symbol.symbol === "{T}" || symbol.symbol === "{Q}";
        cardSymbols[symbol.symbol] = { url: symbol.svg_uri, shadow: shadow };
      }
    });
  }

  try {
    var cached = JSON.parse(localStorage.getItem("scryfallSymbology"));
    if (cached && cached.length) {
      apply(cached);
    }
  } catch (e) { /* ignore malformed cache */ }

  $.ajax({
    url: "https://api.scryfall.com/symbology",
    dataType: "json",
    cache: false,
    success: function(response) {
      if (!response || !response.data) return;
      apply(response.data);
      try {
        localStorage.setItem("scryfallSymbology", JSON.stringify(response.data));
      } catch (e) { /* storage full or unavailable */ }
      // Symbols may have arrived after cards were already rendered; re-render so
      // the literal "{W}" codes get replaced with their symbols.
      if (typeof currentCardset !== "undefined" && currentCardset) {
        setDraftmancerCardSet(currentCardset);
      }
    }
  });
}

/// Replaces Scryfall symbol codes ({W}, {T}, {G/U}, etc.) in an already
/// HTML-escaped string with inline <img> SVG symbols that scale with the font.
/// Unknown codes are left as their literal text.
function renderManaSymbols(escapedText) {
  if (!escapedText) return escapedText || "";
  return escapedText.replace(/\{[^}]+\}/g, function(match) {
    var entry = cardSymbols[match];
    if (!entry) return match;
    var label = match.replace(/[{}]/g, "");
    var className = "cc-symbol" + (entry.shadow ? " cc-symbol-shadow" : "");
    return "<img class='" + className + "' src='" + entry.url + "' alt='{" + label + "}'>";
  });
}

/// Returns the best image URL for a card or a single card face.
function faceImageURL(obj) {
  if (!obj) return "";
  if (obj.image) return obj.image;
  var uris = obj.image_uris;
  if (uris) {
    return uris.en || uris.normal || uris.large || uris.png || "";
  }
  return "";
}

/// Returns the front image URL of a card, falling back to its first face.
function frontImageURL(element) {
  var direct = faceImageURL(element);
  if (direct) return direct;
  if (element.card_faces && element.card_faces[0]) {
    return faceImageURL(element.card_faces[0]);
  }
  return "";
}

/// Returns [frontURL] or [frontURL, backURL] for double-faced cards.
function cardImageURLs(element) {
  if (element.card_faces && element.card_faces.length >= 2 &&
      element.card_faces[0].image_uris && element.card_faces[1].image_uris) {
    return [faceImageURL(element.card_faces[0]), faceImageURL(element.card_faces[1])];
  }
  var urls = [frontImageURL(element)];
  if (element.back) {
    var backURL = faceImageURL(element.back);
    if (backURL) urls.push(backURL);
  }
  return urls;
}

/// Normalizes a card or a card face into the fields the detail view renders.
function faceInfo(obj) {
  var typeLine = obj.type_line || "";
  if (!typeLine) {
    typeLine = obj.type || "";
    if (obj.subtypes && obj.subtypes.length) {
      typeLine += " — " + obj.subtypes.join(" ");
    }
  }

  var pt = "";
  if (obj.power != undefined && obj.toughness != undefined) {
    pt = obj.power.toString() + "/" + obj.toughness.toString();
  } else if (obj.loyalty != undefined) {
    pt = obj.loyalty.toString();
  }

  var oracleHTML = "";
  if (obj.oracle_text) {
    // Reminder text is wrapped in parentheses and rendered in italics, like
    // Scryfall. Symbols inside reminder text still render as images.
    oracleHTML = renderManaSymbols(escapeHTML(obj.oracle_text))
      .replace(/\([^)\n]*\)/g, "<i>$&</i>")
      .replace(/\n/g, "<br />");
  }

  // When a card has a flavor name (e.g. a Universes Within version), show the
  // flavor name as the display name and the real Magic name underneath it.
  var displayName = obj.flavor_name || obj.name || "";
  var realName = (obj.flavor_name && obj.name && obj.flavor_name !== obj.name) ? obj.name : "";

  return {
    name: displayName,
    realName: realName,
    manaCost: obj.mana_cost || "",
    typeLine: typeLine,
    oracleHTML: oracleHTML,
    pt: pt,
    artist: obj.artist || ""
  };
}

/// Only transform and modal_dfc cards physically flip; other multi-faced cards
/// (split, adventure, etc.) are a single static image.
function isFlippable(element) {
  var layout = (element.layout || "").toLowerCase();
  if (layout !== "transform" && layout !== "modal_dfc") {
    return false;
  }
  return cardImageURLs(element).length > 1;
}

/// Returns [{info}] for every face of a card, so the detail view can show the
/// text of all faces (e.g. both halves of a split card) regardless of flipping.
function cardTextFaces(element) {
  if (element.card_faces && element.card_faces.length >= 2) {
    return element.card_faces.map(function(face) {
      return { info: faceInfo(face) };
    });
  }
  var faces = [{ info: faceInfo(element) }];
  if (element.back) {
    faces.push({ info: faceInfo(element.back) });
  }
  return faces;
}

var FLIP_ICON = "<svg viewBox='0 0 24 24' width='18' height='18' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round' aria-hidden='true'><path d='M21 2v6h-6'/><path d='M3 12a9 9 0 0 1 15-6.7L21 8'/><path d='M3 22v-6h6'/><path d='M21 12a9 9 0 0 1-15 6.7L3 16'/></svg>";

/// Creates a flip toggle button that flips the nearest ancestor matching `selector`.
function makeFlipButton(selector) {
  var btn = document.createElement("button");
  btn.type = "button";
  btn.className = "cc-flip-btn";
  btn.title = "Flip card";
  btn.setAttribute("aria-label", "Flip card");
  btn.innerHTML = FLIP_ICON;
  btn.addEventListener("click", function(event) {
    event.preventDefault();
    event.stopPropagation();
    var card = btn.closest(selector);
    if (card) {
      card.classList.toggle("cc-flipped");
    }
  });
  return btn;
}

/// Creates a button that copies the card's raw Swiftfall JSON to the clipboard.
function makeCopyButton(element) {
  var btn = document.createElement("button");
  btn.type = "button";
  btn.className = "cc-btn-small cc-copy-btn";
  btn.textContent = "Copy JSON";
  btn.addEventListener("click", function(event) {
    event.preventDefault();
    event.stopPropagation();
    navigator.clipboard.writeText(JSON.stringify(element, null, 2)).then(function() {
      btn.textContent = "Copied!";
      btn.classList.add("cc-copied");
      setTimeout(function() {
        btn.textContent = "Copy JSON";
        btn.classList.remove("cc-copied");
      }, 1200);
    });
  });
  return btn;
}

/// Builds the combined display name (with flavor names and back face) for the grid label.
function combinedCardName(element) {
  var name = element.flavor_name || element.name;
  if (element.back && element.back.flavor_name) {
    name += " // " + element.back.flavor_name;
  }
  if (element.flavor_name) {
    name += " (" + element.name + ")";
  }
  return name;
}

function setDraftmancerCardSet(cardset) {
  document.getElementById("cardset-title").innerHTML = cardset.name;
  currentCardset = cardset;

  document.querySelectorAll('.cc-tab-btn').forEach(function(btn) {
    btn.classList.toggle('active', !cardset.is_search && btn.textContent === cardset.name);
  });

  var filters = document.getElementById("filters");
  filters.innerHTML = "";

  var allBtn = document.createElement("button");
  allBtn.className = "cc-filter-btn" + (!currentRarity ? " active" : "");
  allBtn.textContent = "All";
  allBtn.onclick = function() {
    currentRarity = null;
    setDraftmancerCardSet(cardset);
  };
  filters.appendChild(allBtn);

  var rarities = ["common", "uncommon", "rare", "mythic", "special"];
  rarities.forEach((rarity) => {
    var button = document.createElement("button");
    button.className = "cc-filter-btn cc-rarity-" + rarity + (currentRarity === rarity ? " active" : "");
    button.textContent = rarity.capitalize();
    button.onclick = function() {
      currentRarity = rarity;
      setDraftmancerCardSet(cardset);
    };
    filters.appendChild(button);
  });

  var p = document.getElementById("download-button");
  p.innerHTML = "";

  if (cardset.string) {
    var downloadButton = document.createElement("button");
    downloadButton.className = "cc-btn";
    downloadButton.textContent = "Download Draftmancer File";
    downloadButton.onclick = function() {
      download(cardset.name + ".txt", cardset.string, "text/plain");
    };
    p.appendChild(downloadButton);
  }

  var showDetails = localStorage.getItem("showDetails") === 'true';
  var viewToggleLabel = document.getElementById("view-toggle-label");
  if (viewToggleLabel) {
    viewToggleLabel.textContent = showDetails ? "Grid View" : "Detail View";
  }

  var container = document.getElementById("cardtable");
  container.innerHTML = "";
  container.className = showDetails ? "cc-card-list" : "cc-card-grid";

  var cards = cardset.cards;

  if (currentRarity) {
    cards = cards.filter((card) => card.rarity == currentRarity);
  }

  if (showDetails) {
    for (var i = 0; i < cards.length; i++) {
      var element = cards[i];
      var faces = cardTextFaces(element);
      var flippable = isFlippable(element);
      var images = cardImageURLs(element);

      var card = document.createElement("div");
      card.className = "cc-card-detail" + (flippable ? " cc-flippable" : "");

      var rarity = "";
      if (element.rarity) {
        rarity = " (" + Array.from(element.rarity)[0].toUpperCase() + ")";
      }
      var setLine = (element.set ? element.set.toUpperCase() : "") + " #" + element.collector_number + rarity;

      // Image column. Only transform / modal_dfc cards flip; everything else
      // shows a single static image.
      var imageCol = document.createElement("div");
      imageCol.className = "cc-card-detail-image";

      var flip = document.createElement("div");
      flip.className = "cc-card-flip";
      if (flippable) {
        flip.innerHTML =
          "<div class='cc-card-face cc-card-front'><img src=\"" + images[0] + "\" loading='lazy'></div>" +
          "<div class='cc-card-face cc-card-back'><img src=\"" + images[1] + "\" loading='lazy'></div>";
      } else {
        flip.innerHTML = "<div class='cc-card-face cc-card-front'><img src=\"" + frontImageURL(element) + "\" loading='lazy'></div>";
      }
      imageCol.appendChild(flip);
      if (flippable) {
        imageCol.appendChild(makeFlipButton(".cc-card-detail"));
      }
      card.appendChild(imageCol);

      // Info column. Every face's text is shown stacked with a divider between
      // them (matching Scryfall's text layout), whether or not the card flips.
      var info = document.createElement("div");
      info.className = "cc-card-detail-info";

      faces.forEach(function(face, faceIndex) {
        var block = document.createElement("div");
        block.className = "cc-face-info";
        var setHTML = faceIndex === 0 ? "<span class='cc-card-set'>" + escapeHTML(setLine) + "</span>" : "";
        var realNameHTML = face.info.realName ? "<span class='cc-card-realname'>" + escapeHTML(face.info.realName) + "</span>" : "";
        block.innerHTML =
          "<div class='cc-card-detail-header'>" +
            "<h3 class='cc-card-name'>" + escapeHTML(face.info.name) + realNameHTML + "</h3>" +
            "<span class='cc-card-mana'>" + renderManaSymbols(escapeHTML(face.info.manaCost)) + "</span>" +
          "</div>" +
          "<div class='cc-card-detail-type'>" +
            "<span>" + escapeHTML(face.info.typeLine) + "</span>" +
            setHTML +
          "</div>" +
          "<div class='cc-card-detail-text'>" + face.info.oracleHTML + "</div>" +
          "<div class='cc-card-detail-footer'>" +
            "<span class='cc-card-artist'>" + (face.info.artist ? "Illustrated by " + escapeHTML(face.info.artist) : "") + "</span>" +
            "<span class='cc-card-pt'>" + escapeHTML(face.info.pt) + "</span>" +
          "</div>";
        info.appendChild(block);
      });

      // A single Copy JSON action for the whole card.
      var actions = document.createElement("div");
      actions.className = "cc-face-actions";
      actions.appendChild(makeCopyButton(element));
      info.appendChild(actions);

      card.appendChild(info);
      container.appendChild(card);
    }
  } else {
    for (var i = 0; i < cards.length; i++) {
      var element = cards[i];
      var flippable = isFlippable(element);
      var images = cardImageURLs(element);

      var card = document.createElement("div");
      card.className = "cc-card" + (flippable ? " cc-flippable" : "");

      var rarity = "";
      if (element.rarity) {
        rarity = " (" + Array.from(element.rarity)[0].toUpperCase() + ")";
      }
      var setLine = (element.set ? element.set.toUpperCase() : "") + " #" + element.collector_number + rarity;

      var media = document.createElement("div");
      media.className = "cc-card-media";

      var flip = document.createElement("div");
      flip.className = "cc-card-flip";
      if (flippable) {
        flip.innerHTML =
          "<div class='cc-card-face cc-card-front'><a href=\"" + images[0] + "\"><img src=\"" + images[0] + "\" loading='lazy'></a></div>" +
          "<div class='cc-card-face cc-card-back'><a href=\"" + images[1] + "\"><img src=\"" + images[1] + "\" loading='lazy'></a></div>";
        media.appendChild(flip);
        media.appendChild(makeFlipButton(".cc-card"));
      } else {
        var frontURL = frontImageURL(element);
        flip.innerHTML = "<div class='cc-card-face cc-card-front'><a href=\"" + frontURL + "\"><img src=\"" + frontURL + "\" loading='lazy'></a></div>";
        media.appendChild(flip);
      }
      card.appendChild(media);

      var label = document.createElement("div");
      label.className = "cc-card-label";
      label.innerHTML = escapeHTML(combinedCardName(element)) + "<br>" + escapeHTML(setLine);
      card.appendChild(label);

      container.appendChild(card);
    }
  }
  
  if (cardset.is_search) {
    setURL(cardset.query, null);
  } else {
    setURL(null, cardset.name);
  }
  
  document.getElementById("filters").hidden = cardset.is_search;
  document.getElementById("query-description").hidden = !cardset.is_search;
  document.getElementById("cardset-title").hidden = cardset.is_search;
}

/// Sets the URL query OR the hash, and clears out the values if null.
function setURL(query, hash) {
  const path = window.location.pathname;
  
  // Update URL
  var location = path;
  
  if (query) {
    const params = new URLSearchParams(window.location.search);
    params.set('q', query);
    location += "?" + params.toString();
  }
  
  if (hash) {
    location += "#" + hash;
  }
  
  window.history.replaceState({}, '', location);
}

function copyableText(draftmancerCard) {
  var string = draftmancerCard.name;
  if (draftmancerCard.mana_cost) {
    string += " " + draftmancerCard.mana_cost;
  }
  string += "\n";
  string += draftmancerCard.type;
  if (draftmancerCard.subtypes) {
    string += " – "
    string += draftmancerCard.subtypes.join(" ");
  }
  
  if (draftmancerCard.rarity) {
    string += " (";
    if (draftmancerCard.set) {
      string += draftmancerCard.set + " "
    }
    string += draftmancerCard.rarity[0].toUpperCase() + ")\n";
  }
  
  if (draftmancerCard.oracle_text) {
    string += draftmancerCard.oracle_text.split("\n").map(line => line.trim()).join("\n");
  }
  
  if (draftmancerCard.power) {
    string += "\n";
    string += draftmancerCard.power + "/" + draftmancerCard.toughness;
  }
  
  if (draftmancerCard.loyalty) {
    string += "\n";
    string += draftmancerCard.loyalty;
  }
  
  return string;
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

function copyOutput() {
  navigator.clipboard.writeText(document.getElementById('output').value || "");
}

function doConvertDeckToMoxfield() {
  $("#progress").html("Working…");
  
  var data = new FormData($("#mainform")[0]);
  
  data.append("deck", document.getElementById("deck").value);
  
  var url = "convert";
  
  if ($("#autofix").prop("checked") == true) {
    url += "?autofix=true"
  } else {
    url += "?autofix=false"
  }
  
  url += "&format=moxfield"
  
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
      
      if (response.error !== undefined) {
        alert(response.error);
        $("#progress").html("");
        return;
      } else if (response.boards) {
        document.getElementById('boards').innerHTML = "";
        
        response.boards.forEach((board) => {
          const button = document.createElement('button');
          button.innerHTML = board.name;
          button.onclick = function() {
            document.getElementById('output').value = board.string;
          }
          document.getElementById('boards').appendChild(button);
        });
        
        document.getElementById('output').value = response.boards[0].string;
        
        $("#progress").html("");
      }
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

function saveDeckToHistory(name) {
  const deck = document.getElementById("deck").value.trim();
  if (!deck || !name) return;

  let decks = JSON.parse(localStorage.getItem("deckHistory") || "[]");

  // Check if a deck with the same name already exists
  const existingIndex = decks.findIndex(d => d.name === name);

  if (existingIndex !== -1) {
    // Overwrite the existing deck's content and update timestamp
    decks[existingIndex].content = deck;
    decks[existingIndex].timestamp = Date.now();
  } else {
    // Add new entry
    decks.push({
      name: name,
      content: deck,
      timestamp: Date.now()
    });
  }

  localStorage.setItem("deckHistory", JSON.stringify(decks));
  populateDeckHistory();

  // Select the newly saved deck
  const select = document.getElementById("deckHistory");
  select.value = deck;
}


function populateDeckHistory() {
  const decks = JSON.parse(localStorage.getItem("deckHistory") || "[]");
  const select = document.getElementById("deckHistory");
  select.innerHTML = '<option value="">-- Select a saved deck --</option>';

  decks
    .sort((a, b) => b.timestamp - a.timestamp)
    .forEach(deck => {
      const opt = document.createElement("option");
      opt.value = deck.content;

      let host = "";
      try {
        const url = new URL(deck.content);
        host = url.hostname.replace("www.", "");
      } catch (e) {
        // Not a valid URL — skip host
      }

      opt.textContent = host ? `${deck.name} (${host})` : deck.name;
      select.appendChild(opt);
    });
}

function loadSelectedDeck() {
  var value = document.getElementById("deckHistory").value;
  if (value) {
    document.getElementById("deck").value = value;
  }
}

function deleteSelectedDeck() {
  const content = document.getElementById("deckHistory").value;
  if (!content) return;

  let decks = JSON.parse(localStorage.getItem("deckHistory") || "[]");

  // Remove the deck that matches the selected content exactly
  decks = decks.filter(deck => deck.content !== content);

  localStorage.setItem("deckHistory", JSON.stringify(decks));
  populateDeckHistory();
  document.getElementById("deck").value = "";
}

function omenpathToggled() {
  localStorage.setItem('omenpath', document.querySelector('#omenpath').checked);
}
