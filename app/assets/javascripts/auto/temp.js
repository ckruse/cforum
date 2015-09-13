jQuery(document).ready(function($){
	if ($('body[data-controller="cf_threads"][data-action="index"]').length > 0 && cforum && !cforum.currentUser) {

		if (!Array.prototype.reduce) {
			Array.prototype.reduce = function(callback /*, initialValue*/) {
				'use strict';
				if (this == null) {
					throw new TypeError('Array.prototype.reduce called on null or undefined');
				}
				if (typeof callback !== 'function') {
					throw new TypeError(callback + ' is not a function');
				}
				var t = Object(this), len = t.length >>> 0, k = 0, value;
				if (arguments.length == 2) {
					value = arguments[1];
				} else {
					while (k < len && !(k in t)) {
						k++;
					}
					if (k >= len) {
						throw new TypeError('Reduce of empty array with no initial value');
					}
					value = t[k++];
				}
				for (; k < len; k++) {
					if (k in t) {
						value = callback(value, t[k], k, t);
					}
				}
				return value;
			};
		}


		var threads_sorted = 'sortDesc';
		// Datum des jüngsten Postings ermitteln
		var gotDates = false;
		function getDates() {
			$('article.threadlist').each(function () {
				var $this = $(this);
				$this.data('newestPostingDate', $this.find('time').map(function(){return $(this).attr('datetime');}).get().reduce(function (prev, current) {
					return prev > current ? prev : current;
				}, ''));
			});
			gotDates = true;
		}

		/*!
		 * jQuery.sortChildren
		 *
		 * Version: 1.0.0
		 *
		 * Author: Rodney Rehm
		 * Web: http://rodneyrehm.de/
		 * See: http://blog.rodneyrehm.de/archives/14-Sorting-Were-Doing-It-Wrong.html
		 *
		 * @license
		 *   MIT License http://www.opensource.org/licenses/mit-license
		 *   GPL v3 http://opensource.org/licenses/GPL-3.0
		 *
		 */
		$.fn.sortChildren = function(map, compare) {
			return this.each(function() {
				var $this = $(this),
					$children = $this.children(),
					_map = [],
					length = $children.length,
					i;

				for (i = 0; i < length ; i++) {
					_map.push({
						index: i,
						value: (map || $.sortChildren.map)($children[i])
					});
				}

				_map.sort(compare || $.sortChildren.compare);

				for (i = 0; i < length ; i++) {
					this.appendChild($children[_map[i].index]);
				}
			});
		};

		$.sortChildren = {
			// default comparison function using String.localeCompare if possible
			compare: function(a, b) {
				if ($.isArray(a.value)) {
					return $.sortChildren.compareList(a.value, b.value);
				}
				return $.sortChildren.compareValues(a.value, b.value);
			},

			compareValues: function(a, b) {
				if (typeof a === "string" && "".localeCompare) {
					return a.localeCompare(b);
				}

				return a === b ? 0 : a > b ? 1 : -1;
			},

			// default comparison function for DESC
			reverse: function(a, b) {
				return -1 * $.sortChildren.compare(a, b);
			},

			// default mapping function returning the elements' lower-cased innerTEXT
			map: function(elem) {
				return $(elem).text().toLowerCase();
			},

			// default comparison function for lists (e.g. table columns)
			compareList: function(a, b) {
				var i = 1,
					length = a.length,
					res = $.sortChildren.compareValues(a[0], b[0]);

				while (res === 0 && i < length) {
					res = $.sortChildren.compareValues(a[i], b[i]);
					i++;
				}

				return res;
			}
		};

		function threadId(thread) {
			return ($(thread).hasClass('sticky') ? '0' : '1') + thread.id;
		}
		function threadIdReverse(thread) {
			return ($(thread).hasClass('sticky') ? '1' : '0') + thread.id;
		}
		function newestPostingDate(thread) {
			return ($(thread).hasClass('sticky') ? '1' : '0') + $(thread).data('newestPostingDate');
		}
		function simpleCompare(a, b) {
			return a.value === b.value ? 0 : a.value > b.value ? 1 : -1;
		}
		function simpleCompareReverse(a, b) {
			return a.value === b.value ? 0 : a.value < b.value ? 1 : -1;
		}

		function sortThreadsAsc() {
			$('[data-controller="cf_threads"] #content .root').sortChildren(threadId, simpleCompare);
			threads_sorted = 'sortAsc';
		}
		function sortThreadsDesc() {
			$('[data-controller="cf_threads"] #content .root').sortChildren(threadIdReverse, simpleCompareReverse);
			threads_sorted = 'sortDesc';
		}
		function sortThreadsPosting() {
			if (!gotDates)
				getDates();
			$('[data-controller="cf_threads"] #content .root').sortChildren(newestPostingDate, simpleCompareReverse);
			threads_sorted = 'sortPosting';
		}

		function sorting(where) {
			var $where = $(where);
			var pos = $where.position();
			$('#sorting').css({
				top: (pos.top + $where.outerHeight()),
				left: pos.left,
				display: 'block',
			});
		}
		function sorted() {
			$('#sorting').delay(500).fadeOut(300);
		}

		var sortingMap = {
			'sortDesc': {
				text: 'neue oben',
				func: sortThreadsDesc },
			'sortAsc': {
				text: 'neue unten',
				func: sortThreadsAsc },
			'sortPosting': {
				text: 'j??te Antwort oben',
				func: sortThreadsPosting }
		};

		function sortThreads(what) {
			if (what.id == threads_sorted)
				return;
			sorting(what);
			$('#sortLinks a').css({
				fontWeight: 'normal',
				cursor: 'pointer',
			});
			setTimeout(function() {
				sortingMap[what.id]['func']();
				$('#' + what.id).css({
					fontWeight: 'bold',
					cursor: 'not-allowed',
				});
				sorted();
				showCurrentThreadValuesToSave();
			}, 50);
		}

		function showCurrentThreadValuesToSave() {
			$('#threadvalues').text('Sortierung: ' + sortingMap[threads_sorted]['text']);
		}
		function showDone(where) {
			var $where = $(where);
			var pos = $where.position();
			$('#saveValueDone').css({
				top: (pos.top + $where.outerHeight()),
				left: pos.left
			}).fadeIn(300).delay(2000).fadeOut(300);
		}

		var $treeFunctions = $('<ul id="tree-functions">'+
			'<li id="sortLinks">Threads sortieren nach: <a id="sortDesc" class="switch">neue oben</a>, <a id="sortAsc" class="switch">neue unten</a>, <a id="sortPosting" class="switch">jüngste Antwort oben</a></li>' +
			'</ul>');
		$('main h1').after($treeFunctions);

		// Sortieren
		$treeFunctions.append('<li id="sorting" class="tooltip">Sortierung läuft.</li>');
		$('#sortLinks a').click(function() { sortThreads(this); });

		// Speichern
		if (!!window.localStorage) {
			$treeFunctions.append('<li>Aktuelle Thread-Einstellungen: <span id="threadvalues" style="display: none"></span> <a id="saveThreadValues" class="switch">im Browser speichern</a>, <a id="clearThreadValues" class="switch">gespeicherte Vorgaben löschen</a></li>');
			$treeFunctions.append('<li id="saveValueDone" class="tooltip">Erledigt.</li>');

			$('#saveThreadValues').click(function () {
				localStorage.setItem('threads_sorted', threads_sorted);
				showDone(this);
			});
			$('#clearThreadValues').click(function () {
				localStorage.removeItem('threads_sorted');
				showDone(this);
			});

			// Wiederherstellen
			var sortValue = localStorage.getItem('threads_sorted');
			sortingMap[sortValue] && sortingMap[sortValue]['func']();

			showCurrentThreadValuesToSave();
		}

		if (threads_sorted) {
			$('#' + threads_sorted).css({
				'font-weight': 'bold',
				'cursor': 'not-allowed',
			});
		}
	}
});

